class MusicFile {
  final String name;
  final String url;
  final int size;
  final DateTime lastModified;
  final String extension;
  final String? relativePath; // 相对路径，用于显示文件夹结构

  MusicFile({
    required this.name,
    required this.url,
    required this.size,
    required this.lastModified,
    required this.extension,
    this.relativePath,
  });

  bool get isAudioFile {
    const audioExtensions = ['.mp3', '.m4a', '.aac', '.flac', '.wav', '.ogg'];
    return audioExtensions.contains(extension.toLowerCase());
  }

  String get displayName {
    return name.replaceAll(RegExp(r'\.[^.]*$'), '');
  }

  /// 获取文件夹路径（用于分组显示）
  String get folderPath {
    if (relativePath == null) return '/';
    final lastSlashIndex = relativePath!.lastIndexOf('/');
    if (lastSlashIndex <= 0) return '/';
    return relativePath!.substring(0, lastSlashIndex);
  }

  /// 获取完整的显示路径
  String get fullDisplayPath {
    if (relativePath == null) return name;
    return relativePath!;
  }

  String get sizeFormatted {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  String get lrcUrl {
    // 获取同名的lrc文件路径
    final dir = url.substring(0, url.lastIndexOf('/'));
    final nameWithoutExt = name.substring(0, name.lastIndexOf('.'));
    return '$dir/$nameWithoutExt.lrc';
  }
}

class WebDAVConnection {
  final String host;
  final String username;
  final String password;
  final String basePath;
  final int port;
  final bool useHttps;
  final int maxScanDepth; // 最大扫描深度，-1表示无限制

  WebDAVConnection({
    required this.host,
    required this.username,
    required this.password,
    this.basePath = '/',
    this.port = 80,
    this.useHttps = false,
    this.maxScanDepth = -1, // 默认无限制递归扫描
  });

  String get serverUrl {
    final protocol = useHttps ? 'https' : 'http';
    final portStr = (useHttps && port == 443) || (!useHttps && port == 80)
        ? ''
        : ':$port';
    return '$protocol://$host$portStr';
  }

  String get baseUrl {
    final protocol = useHttps ? 'https' : 'http';
    final portStr = (useHttps && port == 443) || (!useHttps && port == 80)
        ? ''
        : ':$port';
    return '$protocol://$host$portStr$basePath';
  }
}

enum PlayerState { stopped, playing, paused, loading, error }

class PlaybackState {
  final PlayerState state;
  final Duration position;
  final Duration duration;
  final MusicFile? currentFile;
  final String? error;

  PlaybackState({
    required this.state,
    required this.position,
    required this.duration,
    this.currentFile,
    this.error,
  });

  PlaybackState copyWith({
    PlayerState? state,
    Duration? position,
    Duration? duration,
    MusicFile? currentFile,
    String? error,
  }) {
    return PlaybackState(
      state: state ?? this.state,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      currentFile: currentFile ?? this.currentFile,
      error: error ?? this.error,
    );
  }
}

class LrcLine {
  final Duration timestamp;
  final String text;

  LrcLine({required this.timestamp, required this.text});

  factory LrcLine.fromString(String line) {
    // 解析LRC格式: [mm:ss.xx]歌词文本
    final timeMatch = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2})\]').firstMatch(line);
    if (timeMatch == null) {
      return LrcLine(timestamp: Duration.zero, text: line);
    }

    final minutes = int.parse(timeMatch.group(1)!);
    final seconds = int.parse(timeMatch.group(2)!);
    final centiseconds = int.parse(timeMatch.group(3)!);

    final timestamp = Duration(
      minutes: minutes,
      seconds: seconds,
      milliseconds: centiseconds * 10,
    );

    final text = line.substring(timeMatch.end).trim();
    return LrcLine(timestamp: timestamp, text: text);
  }
}

class LrcData {
  final List<LrcLine> lines;
  final String? title;
  final String? artist;
  final String? album;

  LrcData({required this.lines, this.title, this.artist, this.album});

  factory LrcData.fromString(String lrcContent) {
    final lines = lrcContent.split('\n');
    final lrcLines = <LrcLine>[];
    String? title, artist, album;

    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isEmpty) continue;

      // 解析元数据
      if (trimmedLine.startsWith('[ti:')) {
        title = trimmedLine.substring(4, trimmedLine.length - 1);
      } else if (trimmedLine.startsWith('[ar:')) {
        artist = trimmedLine.substring(4, trimmedLine.length - 1);
      } else if (trimmedLine.startsWith('[al:')) {
        album = trimmedLine.substring(4, trimmedLine.length - 1);
      } else if (trimmedLine.contains(RegExp(r'\[\d{2}:\d{2}\.\d{2}\]'))) {
        // 解析歌词行
        final lrcLine = LrcLine.fromString(trimmedLine);
        if (lrcLine.text.isNotEmpty) {
          lrcLines.add(lrcLine);
        }
      }
    }

    // 按时间戳排序
    lrcLines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return LrcData(lines: lrcLines, title: title, artist: artist, album: album);
  }

  LrcLine? getCurrentLine(Duration position) {
    if (lines.isEmpty) return null;

    LrcLine? currentLine;
    for (final line in lines) {
      if (line.timestamp <= position) {
        currentLine = line;
      } else {
        break;
      }
    }
    return currentLine;
  }

  int getCurrentLineIndex(Duration position) {
    if (lines.isEmpty) return -1;

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].timestamp > position) {
        return i - 1;
      }
    }
    return lines.length - 1;
  }
}
