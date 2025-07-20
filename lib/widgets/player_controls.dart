import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/music_player_provider.dart';
import '../models/music_models.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MusicPlayerProvider>(
      builder: (context, musicProvider, child) {
        final playbackState = musicProvider.playbackState;
        final currentFile = playbackState.currentFile;

        if (currentFile == null) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 进度条
              _buildProgressBar(context, playbackState),
              
              // 控制按钮和信息
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // 歌曲信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentFile.displayName,
                            style: Theme.of(context).textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${_formatDuration(playbackState.position)} / ${_formatDuration(playbackState.duration)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // 控制按钮
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 随机播放
                        IconButton(
                          icon: Icon(
                            Icons.shuffle,
                            color: musicProvider.isShuffled 
                                ? Theme.of(context).colorScheme.primary 
                                : null,
                          ),
                          onPressed: () => musicProvider.toggleShuffle(),
                          tooltip: '随机播放',
                        ),
                        
                        // 上一首
                        IconButton(
                          icon: const Icon(Icons.skip_previous),
                          onPressed: musicProvider.playlist.length > 1 
                              ? () => musicProvider.previous()
                              : null,
                          tooltip: '上一首',
                        ),
                        
                        // 播放/暂停
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _getPlayPauseIcon(playbackState.state),
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            onPressed: () => _handlePlayPause(musicProvider, playbackState.state),
                            tooltip: playbackState.state == PlayerState.playing ? '暂停' : '播放',
                          ),
                        ),
                        
                        // 下一首
                        IconButton(
                          icon: const Icon(Icons.skip_next),
                          onPressed: musicProvider.playlist.length > 1 
                              ? () => musicProvider.next()
                              : null,
                          tooltip: '下一首',
                        ),
                        
                        // 重复播放
                        IconButton(
                          icon: Icon(
                            Icons.repeat,
                            color: musicProvider.isRepeat 
                                ? Theme.of(context).colorScheme.primary 
                                : null,
                          ),
                          onPressed: () => musicProvider.toggleRepeat(),
                          tooltip: '重复播放',
                        ),
                      ],
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

  Widget _buildProgressBar(BuildContext context, PlaybackState playbackState) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        trackHeight: 2,
      ),
      child: Slider(
        value: playbackState.duration.inMilliseconds > 0
            ? (playbackState.position.inMilliseconds / playbackState.duration.inMilliseconds).clamp(0.0, 1.0)
            : 0.0,
        onChanged: (value) {
          final musicProvider = context.read<MusicPlayerProvider>();
          final newPosition = Duration(
            milliseconds: (value * playbackState.duration.inMilliseconds).round(),
          );
          musicProvider.seekTo(newPosition);
        },
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
      ),
    );
  }

  IconData _getPlayPauseIcon(PlayerState state) {
    switch (state) {
      case PlayerState.playing:
        return Icons.pause;
      case PlayerState.loading:
        return Icons.hourglass_empty;
      case PlayerState.error:
        return Icons.error;
      default:
        return Icons.play_arrow;
    }
  }

  void _handlePlayPause(MusicPlayerProvider musicProvider, PlayerState state) {
    if (state == PlayerState.playing) {
      musicProvider.pause();
    } else if (state == PlayerState.paused) {
      musicProvider.play();
    } else if (musicProvider.currentFile != null) {
      musicProvider.play();
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
