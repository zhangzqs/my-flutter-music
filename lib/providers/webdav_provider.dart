import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;
import '../models/music_models.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

class WebDAVProvider extends ChangeNotifier {
  webdav.Client? _client;
  WebDAVConnection? _connection;
  List<MusicFile> _musicFiles = [];
  bool _isLoading = false;
  String? _error;
  String _currentPath = '/';
  Function(String, String, String)? _onCredentialsUpdate;

  webdav.Client? get client => _client;
  WebDAVConnection? get connection => _connection;
  List<MusicFile> get musicFiles => _musicFiles;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentPath => _currentPath;
  bool get isConnected => _client != null;
  
  // 递归扫描相关状态
  bool _isRecursiveScanning = false;
  int _totalFoldersScanned = 0;
  int _totalMusicFilesFound = 0;
  String _currentScanningFolder = '';
  
  bool get isRecursiveScanning => _isRecursiveScanning;
  int get totalFoldersScanned => _totalFoldersScanned;
  int get totalMusicFilesFound => _totalMusicFilesFound;
  String get currentScanningFolder => _currentScanningFolder;

  WebDAVProvider() {
    _loadSavedConnection();
  }

  void setCredentialsUpdateCallback(Function(String, String, String) callback) {
    _onCredentialsUpdate = callback;
  }

  Future<void> _loadSavedConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final host = prefs.getString('webdav_host');
      final username = prefs.getString('webdav_username');
      final password = prefs.getString('webdav_password');
      final basePath = prefs.getString('webdav_base_path') ?? '/';
      final port = prefs.getInt('webdav_port') ?? 80;
      final useHttps = prefs.getBool('webdav_use_https') ?? false;
      final maxScanDepth = prefs.getInt('webdav_max_scan_depth') ?? -1;

      if (host != null && username != null && password != null) {
        final connection = WebDAVConnection(
          host: host,
          username: username,
          password: password,
          basePath: basePath,
          port: port,
          useHttps: useHttps,
          maxScanDepth: maxScanDepth,
        );
        await connect(connection, saveCredentials: false);
      }
    } catch (e) {
      debugPrint('Error loading saved connection: $e');
    }
  }

  Future<bool> connect(
    WebDAVConnection connection, {
    bool saveCredentials = true,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      // 调试日志
      debugPrint('WebDAV Connection Details:');
      debugPrint('  Host: ${connection.host}');
      debugPrint('  Port: ${connection.port}');
      debugPrint('  BasePath: ${connection.basePath}');
      debugPrint('  UseHTTPS: ${connection.useHttps}');
      debugPrint('  BaseURL: ${connection.baseUrl}');

      final client = webdav.newClient(
        connection.baseUrl,
        user: connection.username,
        password: connection.password,
      );
      await client.ping();

      _client = client;
      _connection = connection;
      _currentPath = '/'; // 使用根路径，因为 baseUrl 已经包含了 basePath

      if (saveCredentials) {
        await _saveConnection(connection);
      }

      // 连接成功后自动开始递归扫描
      await scanAllMusicFiles();
      
      _setLoading(false);
      
      // 通知音乐播放器Provider更新凭据
      _onCredentialsUpdate?.call(connection.serverUrl, connection.username, connection.password);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('连接失败: $e');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }

  Future<void> _saveConnection(WebDAVConnection connection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('webdav_host', connection.host);
    await prefs.setString('webdav_username', connection.username);
    await prefs.setString('webdav_password', connection.password);
    await prefs.setString('webdav_base_path', connection.basePath);
    await prefs.setInt('webdav_port', connection.port);
    await prefs.setBool('webdav_use_https', connection.useHttps);
    await prefs.setInt('webdav_max_scan_depth', connection.maxScanDepth);
  }

  Future<void> loadFiles([String? customPath]) async {
    if (_client == null || _connection == null) return;

    try {
      _setLoading(true);
      _setError(null);

      final targetPath = customPath ?? _currentPath;
      // 确保路径以 / 开头，但不重复添加 basePath
      final normalizedPath = targetPath.startsWith('/') ? targetPath : '/$targetPath';
      final files = await _client!.readDir(normalizedPath);

      _musicFiles = files
          .where((file) => !file.isDir!)
          .map(
            (file) => MusicFile(
              name: file.name!,
              url: '${_connection!.serverUrl}${connection!.basePath}${file.path!}',
              size: file.size ?? 0,
              lastModified: file.mTime ?? DateTime.now(),
              extension: path.extension(file.name!),
            ),
          )
          .where((file) => file.isAudioFile)
          .toList();

      if (customPath != null) {
        _currentPath = customPath;
      }

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('加载文件失败: $e');
      _setLoading(false);
      notifyListeners();
    }
  }

  /// 递归扫描所有子文件夹中的音乐文件
  Future<void> scanAllMusicFiles([String? startPath, int? maxDepth]) async {
    if (_client == null || _connection == null) return;

    try {
      _isRecursiveScanning = true;
      _totalFoldersScanned = 0;
      _totalMusicFilesFound = 0;
      _currentScanningFolder = '';
      _setError(null);
      
      notifyListeners();

      final scanPath = startPath ?? _currentPath;
      final scanDepth = maxDepth ?? _connection!.maxScanDepth;
      final List<MusicFile> allMusicFiles = [];
      
      debugPrint('开始递归扫描音乐文件，起始路径: $scanPath');
      debugPrint('最大扫描深度: ${scanDepth == -1 ? "无限制" : scanDepth}');
      
      await _recursiveScanFolder(scanPath, allMusicFiles, 0, scanDepth);
      
      _musicFiles = allMusicFiles;
      _isRecursiveScanning = false;
      
      debugPrint('递归扫描完成！');
      debugPrint('  扫描文件夹数: $_totalFoldersScanned');
      debugPrint('  找到音乐文件数: $_totalMusicFilesFound');
      
      notifyListeners();
    } catch (e) {
      _setError('递归扫描失败: $e');
      _isRecursiveScanning = false;
      notifyListeners();
      debugPrint('递归扫描错误: $e');
    }
  }

  /// 递归扫描单个文件夹
  Future<void> _recursiveScanFolder(String folderPath, List<MusicFile> musicFiles, int currentDepth, int maxDepth) async {
    try {
      // 检查深度限制
      if (maxDepth != -1 && currentDepth >= maxDepth) {
        debugPrint('已达到最大扫描深度 $maxDepth，停止扫描: $folderPath');
        return;
      }
      
      _currentScanningFolder = folderPath;
      _totalFoldersScanned++;
      notifyListeners();
      
      debugPrint('扫描文件夹: $folderPath (深度: $currentDepth)');
      
      // 确保路径格式正确
      final normalizedPath = folderPath.startsWith('/') ? folderPath : '/$folderPath';
      final files = await _client!.readDir(normalizedPath);
      
      // 处理当前文件夹中的音乐文件
      final currentFolderMusicFiles = files
          .where((file) => !file.isDir!)
          .map((file) => MusicFile(
                name: file.name!,
                url: '${_connection!.serverUrl}${connection!.basePath}${file.path!}',
                size: file.size ?? 0,
                lastModified: file.mTime ?? DateTime.now(),
                extension: path.extension(file.name!),
                relativePath: file.path!, // 保存相对路径信息
              ))
          .where((file) => file.isAudioFile)
          .toList();
      
      musicFiles.addAll(currentFolderMusicFiles);
      _totalMusicFilesFound += currentFolderMusicFiles.length;
      
      if (currentFolderMusicFiles.isNotEmpty) {
        debugPrint('  在 $folderPath 中找到 ${currentFolderMusicFiles.length} 个音乐文件');
      }
      
      // 递归扫描子文件夹（如果未达到深度限制）
      if (maxDepth == -1 || currentDepth < maxDepth) {
        final subDirectories = files.where((file) => file.isDir!).toList();
        
        for (final dir in subDirectories) {
          // 跳过隐藏文件夹和系统文件夹
          if (dir.name!.startsWith('.') || 
              dir.name! == 'Trash' || 
              dir.name! == 'RecycleBin' ||
              dir.name! == '@eaDir') {
            continue;
          }
          
          await _recursiveScanFolder(dir.path!, musicFiles, currentDepth + 1, maxDepth);
        }
      }
      
    } catch (e) {
      debugPrint('扫描文件夹 $folderPath 时出错: $e');
      // 继续扫描其他文件夹，不中断整个过程
    }
  }

  Future<void> navigateToDirectory(String dirPath) async {
    await loadFiles(dirPath);
  }

  Future<void> navigateUp() async {
    if (_currentPath == '/') return;

    final parentPath = path.dirname(_currentPath);
    await loadFiles(parentPath);
  }

  Future<void> refresh() async {
    await loadFiles();
  }

  void disconnect() {
    _client = null;
    _connection = null;
    _musicFiles.clear();
    _currentPath = '/';
    _setError(null);
    notifyListeners();
  }

  Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('webdav_host');
    await prefs.remove('webdav_username');
    await prefs.remove('webdav_password');
    await prefs.remove('webdav_base_path');
    await prefs.remove('webdav_port');
    await prefs.remove('webdav_use_https');
    await prefs.remove('webdav_max_scan_depth');
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  void _setError(String? error) {
    _error = error;
  }
}
