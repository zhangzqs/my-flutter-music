import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:charset/charset.dart';
import '../models/music_models.dart';

class LyricsService {
  static final LyricsService _instance = LyricsService._internal();
  factory LyricsService() => _instance;
  LyricsService._internal();

  final Map<String, LrcData?> _lyricsCache = {};

  Future<LrcData?> loadLyrics(
    MusicFile musicFile,
    String username,
    String password,
  ) async {
    final lrcUrl = musicFile.lrcUrl;

    // 检查缓存
    if (_lyricsCache.containsKey(lrcUrl)) {
      return _lyricsCache[lrcUrl];
    }

    try {
      debugPrint('Loading lyrics from: $lrcUrl');

      final response = await http.get(
        Uri.parse(lrcUrl),
        headers: {
          'Authorization': 'Basic ${_getBasicAuth(username, password)}',
        },
      );
      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final lrcContent = _decodeContentWithAutoDetection(response.bodyBytes);
        debugPrint('Lyrics content decoded successfully');
        if (lrcContent.isNotEmpty) {
          final lrcData = LrcData.fromString(lrcContent);
          _lyricsCache[lrcUrl] = lrcData;
          debugPrint(
            'Lyrics loaded successfully: ${lrcData.lines.length} lines',
          );
          return lrcData;
        }
      } else if (response.statusCode == 404) {
        debugPrint('No lyrics file found for: ${musicFile.name}');
      } else {
        debugPrint('Failed to load lyrics: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading lyrics: $e');
    }

    // 缓存空结果避免重复请求
    _lyricsCache[lrcUrl] = null;
    return null;
  }

  String _getBasicAuth(String username, String password) {
    final credentials = '$username:$password';
    final encoded = base64Encode(utf8.encode(credentials));
    return encoded;
  }

  /// 自动检测字符编码并解码内容
  String _decodeContentWithAutoDetection(List<int> bytes) {
    if (bytes.isEmpty) return '';

    // 尝试多种编码方式
    final encodings = [
      'utf-8',
      'gbk',
      'gb2312',
      'big5',
      'shift_jis',
      'euc-kr',
      'iso-8859-1',
      'windows-1252',
    ];

    // 首先检测BOM
    String? bomDetectedEncoding = _detectBomEncoding(bytes);
    if (bomDetectedEncoding != null) {
      try {
        return _decodeWithCharset(bytes, bomDetectedEncoding);
      } catch (e) {
        debugPrint('Failed to decode with BOM-detected encoding: $bomDetectedEncoding');
      }
    }

    // 尝试各种编码
    for (String encodingName in encodings) {
      try {
        String decoded = _decodeWithCharset(bytes, encodingName);
        // 简单验证：检查是否包含有效的LRC格式内容
        if (_isValidLrcContent(decoded)) {
          debugPrint('Successfully decoded with encoding: $encodingName');
          return decoded;
        }
      } catch (e) {
        debugPrint('Failed to decode with $encodingName: $e');
        continue;
      }
    }

    // 如果所有编码都失败，使用UTF-8的容错模式
    debugPrint('All encoding attempts failed, using UTF-8 with error handling');
    return utf8.decode(bytes, allowMalformed: true);
  }

  /// 使用charset包进行解码
  String _decodeWithCharset(List<int> bytes, String encodingName) {
    try {
      switch (encodingName.toLowerCase()) {
        case 'utf-8':
          return utf8.decode(bytes);
        case 'gbk':
        case 'gb2312':
          // 尝试使用charset包解码GBK
          try {
            return const GbkCodec().decode(bytes);
          } catch (e) {
            // 如果GBK解码失败，fallback到latin1
            return latin1.decode(bytes);
          }
        case 'big5':
          // Big5编码，先用latin1读取再尝试转换
          return latin1.decode(bytes);
        case 'shift_jis':
          // 日文编码，先用latin1读取
          return latin1.decode(bytes);
        case 'euc-kr':
          // 韩文编码，先用latin1读取
          return latin1.decode(bytes);
        case 'iso-8859-1':
        case 'latin1':
          return latin1.decode(bytes);
        case 'windows-1252':
          return latin1.decode(bytes);
        default:
          return utf8.decode(bytes);
      }
    } catch (e) {
      throw Exception('Failed to decode with $encodingName: $e');
    }
  }

  /// 检测BOM编码
  String? _detectBomEncoding(List<int> bytes) {
    if (bytes.length >= 3) {
      // UTF-8 BOM: EF BB BF
      if (bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
        debugPrint('Detected UTF-8 BOM');
        return 'utf-8';
      }
    }

    if (bytes.length >= 2) {
      // UTF-16 LE BOM: FF FE
      if (bytes[0] == 0xFF && bytes[1] == 0xFE) {
        debugPrint('Detected UTF-16 LE BOM, using UTF-8 fallback');
        return 'utf-8';
      }
      // UTF-16 BE BOM: FE FF
      if (bytes[0] == 0xFE && bytes[1] == 0xFF) {
        debugPrint('Detected UTF-16 BE BOM, using UTF-8 fallback');
        return 'utf-8';
      }
    }

    return null;
  }

  /// 验证是否为有效的LRC内容
  bool _isValidLrcContent(String content) {
    if (content.isEmpty) return false;
    
    // 检查是否包含时间标签格式 [mm:ss.xx] 或 [mm:ss]
    final timeTagRegex = RegExp(r'\[\d{1,2}:\d{2}(\.\d{1,3})?\]');
    
    // 如果包含时间标签，认为是有效的LRC内容
    if (timeTagRegex.hasMatch(content)) {
      return true;
    }
    
    // 如果包含LRC元数据标签
    final metaTagRegex = RegExp(r'\[(ti|ar|al|by|offset|re|ve):[^\]]*\]');
    if (metaTagRegex.hasMatch(content)) {
      return true;
    }
    
    // 如果内容看起来像歌词（包含换行和一些文字），也接受
    if (content.contains('\n') && content.trim().length > 10) {
      return true;
    }
    
    return false;
  }

  void clearCache() {
    _lyricsCache.clear();
  }

  void removeCacheEntry(String url) {
    _lyricsCache.remove(url);
  }
}
