import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_player_provider.dart';

class LyricsDisplay extends StatefulWidget {
  const LyricsDisplay({super.key});

  @override
  State<LyricsDisplay> createState() => _LyricsDisplayState();
}

class _LyricsDisplayState extends State<LyricsDisplay> {
  late ScrollController _scrollController;
  int? _lastCurrentLineIndex;
  bool _userScrolling = false;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // 监听用户滚动
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// 监听滚动事件，检测用户是否在手动滚动
  void _onScroll() {
    // 当用户手动滚动时，暂停自动滚动
    if (!_userScrolling) {
      _userScrolling = true;
      
      // 3秒后重新允许自动滚动
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _userScrolling = false;
        }
      });
    }
  }

  /// 自动滚动到当前歌词行
  void _scrollToCurrentLine(int? currentLineIndex, int totalLines) {
    if (currentLineIndex == null || 
        currentLineIndex == _lastCurrentLineIndex ||
        !_scrollController.hasClients ||
        _userScrolling) {
      return;
    }

    _lastCurrentLineIndex = currentLineIndex;

    // 使用延迟确保UI已经渲染完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToLineWithAccurateCalculation(currentLineIndex);
    });
  }

  /// 使用更精确的计算方法滚动到指定行
  void _scrollToLineWithAccurateCalculation(int lineIndex) {
    // 每行的精确高度计算（根据实际UI组件的尺寸）
    const double itemVerticalPadding = 12.0 * 2; // 上下padding
    const double itemVerticalMargin = 4.0 * 2;   // 上下margin
    
    // 文字行高计算（考虑统一字体大小和行高）
    const double fontSize = 18.0; // 统一字体大小
    const double lineHeight = 1.5;   // CSS line-height
    const double textHeight = fontSize * lineHeight; // 文字实际高度
    
    const double totalItemHeight = itemVerticalPadding + itemVerticalMargin + textHeight;
    
    // ListView的额外padding
    const double listPadding = 100.0; // ListView顶部padding
    
    // 获取视口信息
    final double viewportHeight = _scrollController.position.viewportDimension;
    final double maxScrollExtent = _scrollController.position.maxScrollExtent;
    final double minScrollExtent = _scrollController.position.minScrollExtent;
    
    // 计算当前行的绝对位置（从ListView顶部开始）
    final double currentItemTop = listPadding + (lineIndex * totalItemHeight);
    
    // 计算为了让当前行居中，需要的滚动偏移量
    // 目标：让当前行的中心位于视口的中心
    final double itemCenter = currentItemTop + (totalItemHeight / 2);
    final double viewportCenter = viewportHeight / 2;
    final double targetScrollOffset = itemCenter - viewportCenter;
    
    // 限制在有效滚动范围内
    final double clampedOffset = targetScrollOffset.clamp(minScrollExtent, maxScrollExtent);
    
    debugPrint('滚动计算详情:');
    debugPrint('  行索引: $lineIndex');
    debugPrint('  单行高度: ${totalItemHeight.toStringAsFixed(1)}px');
    debugPrint('  行顶部位置: ${currentItemTop.toStringAsFixed(1)}px');
    debugPrint('  行中心位置: ${itemCenter.toStringAsFixed(1)}px');
    debugPrint('  视口中心: ${viewportCenter.toStringAsFixed(1)}px');
    debugPrint('  目标滚动偏移: ${targetScrollOffset.toStringAsFixed(1)}px');
    debugPrint('  最终滚动偏移: ${clampedOffset.toStringAsFixed(1)}px');

    // 平滑滚动到目标位置
    _scrollController.animateTo(
      clampedOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerProvider>(
      builder: (context, musicProvider, child) {
        final lyrics = musicProvider.currentLyrics;
        final currentLineIndex = musicProvider.currentLyricLineIndex;
        
        // 当歌词行变化时自动滚动
        if (lyrics != null && lyrics.lines.isNotEmpty) {
          _scrollToCurrentLine(currentLineIndex, lyrics.lines.length);
        }
        
        if (lyrics == null || lyrics.lines.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无歌词',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '请确保音乐文件同目录下有同名的.lrc文件',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 歌曲信息
              if (lyrics.title != null || lyrics.artist != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (lyrics.title != null)
                        Text(
                          lyrics.title!,
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                      if (lyrics.artist != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          lyrics.artist!,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      if (lyrics.album != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          lyrics.album!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),

              // 歌词列表
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      itemCount: lyrics.lines.length,
                      padding: const EdgeInsets.symmetric(vertical: 100), // 增加上下padding，确保首尾歌词也能居中
                      itemBuilder: (context, index) {
                        final line = lyrics.lines[index];
                        final isCurrentLine = index == currentLineIndex;
                        final isPastLine = index < currentLineIndex;

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          decoration: isCurrentLine
                              ? BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                )
                              : null,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: isCurrentLine
                                  ? Theme.of(context).colorScheme.primary
                                  : isPastLine
                                      ? Theme.of(context).colorScheme.outline.withOpacity(0.7)
                                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                              fontWeight: isCurrentLine ? FontWeight.bold : FontWeight.normal,
                              fontSize: 18, // 统一字体大小，避免动态大小影响布局计算
                              height: 1.5, // 增加行高
                            ) ?? const TextStyle(),
                            child: Text(
                              line.text,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // 中心指示线（调试用，可选）
                    if (currentLineIndex >= 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          child: Center(
                            child: Container(
                              height: 3,
                              margin: const EdgeInsets.symmetric(horizontal: 30),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                    Theme.of(context).colorScheme.primary.withOpacity(0.5),
                                    Colors.transparent,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
