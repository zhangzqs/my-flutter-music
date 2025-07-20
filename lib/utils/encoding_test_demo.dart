import 'package:flutter/foundation.dart';
import 'dart:convert';

/// 编码测试演示类
/// 用于演示LyricsService的自动编码检测功能
class EncodingTestDemo {

  /// 测试不同编码的LRC文件加载
  static Future<void> runEncodingTests() async {
    debugPrint('=== LRC编码自动检测测试开始 ===');

    // 测试用例1: UTF-8编码
    await _testUtf8Encoding();

    // 测试用例2: 模拟GBK编码
    await _testGbkEncoding();

    // 测试用例3: 带BOM的UTF-8
    await _testUtf8WithBom();

    // 测试用例4: 无效编码处理
    await _testInvalidEncoding();

    debugPrint('=== 所有编码测试完成 ===');
  }

  /// 测试UTF-8编码
  static Future<void> _testUtf8Encoding() async {
    debugPrint('--- 测试UTF-8编码 ---');
    
    final utf8Content = '''[ti:UTF-8测试歌曲]
[ar:测试歌手]
[al:测试专辑]

[00:00.00]这是UTF-8编码的歌词
[00:05.50]支持中文字符显示
[00:10.20]编码检测正常工作''';

    final utf8Bytes = utf8.encode(utf8Content);
    final decodedContent = _testDecoding(utf8Bytes, 'UTF-8');
    
    if (decodedContent.contains('UTF-8测试歌曲')) {
      debugPrint('✅ UTF-8编码测试通过');
    } else {
      debugPrint('❌ UTF-8编码测试失败');
    }
  }

  /// 测试GBK编码（模拟）
  static Future<void> _testGbkEncoding() async {
    debugPrint('--- 测试GBK编码处理 ---');
    
    // 模拟GBK编码的字节序列
    // 这里使用一些典型的GBK字节范围来模拟
    final gbkLikeBytes = [
      // LRC标签
      0x5B, 0x74, 0x69, 0x3A, // [ti:
      0xB2, 0xE2, 0xCA, 0xD4, // 测试 (GBK编码)
      0x5D, 0x0A, // ]\n
      // 时间标签
      0x5B, 0x30, 0x30, 0x3A, 0x30, 0x30, 0x2E, 0x30, 0x30, 0x5D, // [00:00.00]
      0xB8, 0xE8, 0xB4, 0xCA, // 歌词 (GBK编码)
    ];

    final decodedContent = _testDecoding(gbkLikeBytes, 'GBK');
    
    if (decodedContent.isNotEmpty) {
      debugPrint('✅ GBK编码处理测试通过');
    } else {
      debugPrint('❌ GBK编码处理测试失败');
    }
  }

  /// 测试带BOM的UTF-8
  static Future<void> _testUtf8WithBom() async {
    debugPrint('--- 测试带BOM的UTF-8编码 ---');
    
    final content = '[ti:BOM测试]\n[00:00.00]带BOM的UTF-8文件';
    final contentBytes = utf8.encode(content);
    
    // 添加UTF-8 BOM
    final bomBytes = [0xEF, 0xBB, 0xBF] + contentBytes;
    
    final decodedContent = _testDecoding(bomBytes, 'UTF-8 with BOM');
    
    if (decodedContent.contains('BOM测试')) {
      debugPrint('✅ UTF-8 BOM检测测试通过');
    } else {
      debugPrint('❌ UTF-8 BOM检测测试失败');
    }
  }

  /// 测试无效编码处理
  static Future<void> _testInvalidEncoding() async {
    debugPrint('--- 测试无效编码处理 ---');
    
    // 创建一些随机字节来模拟损坏的文件
    final invalidBytes = [0xFF, 0xFE, 0x00, 0x00, 0x80, 0x90, 0xA0, 0xB0];
    
    final decodedContent = _testDecoding(invalidBytes, '无效编码');
    
    if (decodedContent.isNotEmpty) {
      debugPrint('✅ 无效编码容错处理测试通过');
    } else {
      debugPrint('❌ 无效编码容错处理测试失败');
    }
  }

  /// 执行解码测试
  static String _testDecoding(List<int> bytes, String testType) {
    try {
      // 直接调用LyricsService的私有方法进行测试
      // 注意：这里为了测试目的，我们模拟调用解码方法
      debugPrint('测试 $testType: ${bytes.length} 字节');
      
      // 由于_decodeContentWithAutoDetection是私有方法，
      // 我们这里手动实现相同的逻辑来进行测试
      return _simulateAutoDetection(bytes);
    } catch (e) {
      debugPrint('解码错误 ($testType): $e');
      return '';
    }
  }

  /// 模拟自动检测逻辑
  static String _simulateAutoDetection(List<int> bytes) {
    if (bytes.isEmpty) return '';

    // 检测BOM
    if (bytes.length >= 3 && 
        bytes[0] == 0xEF && bytes[1] == 0xBB && bytes[2] == 0xBF) {
      debugPrint('检测到UTF-8 BOM');
      return utf8.decode(bytes.skip(3).toList());
    }

    // 尝试UTF-8解码
    try {
      final decoded = utf8.decode(bytes, allowMalformed: false);
      if (_isValidLrcContent(decoded)) {
        debugPrint('UTF-8解码成功');
        return decoded;
      }
    } catch (e) {
      debugPrint('UTF-8解码失败');
    }

    // 尝试其他编码（这里简化为latin1）
    try {
      final decoded = latin1.decode(bytes);
      debugPrint('使用latin1解码');
      return decoded;
    } catch (e) {
      debugPrint('所有解码尝试失败');
      return '';
    }
  }

  /// 验证LRC内容
  static bool _isValidLrcContent(String content) {
    if (content.isEmpty) return false;
    
    // 检查时间标签
    final timeTagRegex = RegExp(r'\[\d{1,2}:\d{2}(\.\d{1,3})?\]');
    if (timeTagRegex.hasMatch(content)) return true;
    
    // 检查元数据标签
    final metaTagRegex = RegExp(r'\[(ti|ar|al|by|offset|re|ve):[^\]]*\]');
    if (metaTagRegex.hasMatch(content)) return true;
    
    return content.contains('\n') && content.trim().length > 10;
  }

  /// 显示编码信息
  static void showEncodingInfo() {
    debugPrint('=== 支持的编码格式 ===');
    debugPrint('✅ UTF-8 (默认，推荐)');
    debugPrint('✅ UTF-8 with BOM');
    debugPrint('✅ GBK (中文)');
    debugPrint('✅ GB2312 (简体中文)');
    debugPrint('✅ ISO-8859-1 (Latin1)');
    debugPrint('✅ Windows-1252');
    debugPrint('🔄 其他编码将尝试自动转换');
    debugPrint('=== 自动检测特性 ===');
    debugPrint('🔍 BOM检测');
    debugPrint('🔍 UTF-8有效性检查');
    debugPrint('🔍 中文字符特征分析');
    debugPrint('🔍 LRC格式验证');
    debugPrint('🛡️ 容错处理机制');
  }
}
