import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/webdav_provider.dart';
import '../providers/music_player_provider.dart';
import '../models/music_models.dart';

class MusicList extends StatelessWidget {
  const MusicList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<WebDAVProvider, MusicPlayerProvider>(
      builder: (context, webdavProvider, musicProvider, child) {
        final files = webdavProvider.musicFiles;

        return Column(
          children: [
            // 扫描状态显示栏
            if (webdavProvider.isRecursiveScanning)
              Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    // 重新扫描按钮
                    ElevatedButton.icon(
                      onPressed: () => webdavProvider.scanAllMusicFiles(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新扫描'),
                    ),
                    const SizedBox(width: 8),
                    // 显示扫描深度信息
                    Expanded(
                      child: Text(
                        '扫描深度: ${webdavProvider.connection?.maxScanDepth == -1 ? "无限制" : webdavProvider.connection?.maxScanDepth}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    // 重新扫描按钮
                    ElevatedButton.icon(
                      onPressed: () => webdavProvider.scanAllMusicFiles(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('重新扫描'),
                    ),
                    const Spacer(),
                    // 显示总文件数和扫描深度
                    Text(
                      '共找到 ${files.length} 首歌曲 (深度: ${webdavProvider.connection?.maxScanDepth == -1 ? "∞" : webdavProvider.connection?.maxScanDepth})',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            
            // 扫描状态显示
            if (webdavProvider.isRecursiveScanning)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '正在扫描: ${webdavProvider.currentScanningFolder}',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '已扫描 ${webdavProvider.totalFoldersScanned} 个文件夹',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          '找到 ${webdavProvider.totalMusicFilesFound} 个音乐文件',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // 音乐文件列表
            Expanded(
              child: _buildMusicFilesList(context, files, musicProvider, webdavProvider),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMusicFilesList(BuildContext context, List<MusicFile> files, MusicPlayerProvider musicProvider, WebDAVProvider webdavProvider) {
    if (files.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_off, size: 64),
            const SizedBox(height: 16),
            const Text('没有找到音乐文件'),
            const SizedBox(height: 8),
            const Text(
              '尝试点击"递归扫描"搜索所有子文件夹',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (!webdavProvider.isRecursiveScanning) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => webdavProvider.scanAllMusicFiles(),
                icon: const Icon(Icons.search),
                label: const Text('开始递归扫描'),
              ),
            ],
          ],
        ),
      );
    }

    // 按文件夹分组显示
    return _buildGroupedMusicList(context, files, musicProvider);
  }

  Widget _buildGroupedMusicList(BuildContext context, List<MusicFile> files, MusicPlayerProvider musicProvider) {
    // 按文件夹路径分组
    final Map<String, List<MusicFile>> groupedFiles = {};
    for (final file in files) {
      final folderPath = file.folderPath;
      groupedFiles.putIfAbsent(folderPath, () => []).add(file);
    }

    // 排序文件夹
    final sortedFolders = groupedFiles.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedFolders.length,
      itemBuilder: (context, folderIndex) {
        final folderPath = sortedFolders[folderIndex];
        final folderFiles = groupedFiles[folderPath]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 文件夹标题
            if (folderPath != '/')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        folderPath,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${folderFiles.length} 首',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            
            // 文件夹内的音乐文件
            ...folderFiles.map((file) => _buildMusicFileItem(context, file, musicProvider, files)),
          ],
        );
      },
    );
  }

  Widget _buildMusicFileItem(BuildContext context, MusicFile file, MusicPlayerProvider musicProvider, List<MusicFile> allFiles) {
    final isCurrentFile = musicProvider.currentFile?.url == file.url;
    final isPlaying = isCurrentFile && musicProvider.playbackState.state == PlayerState.playing;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isCurrentFile
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          child: Icon(
            isPlaying ? Icons.music_note : Icons.audio_file,
            color: isCurrentFile
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        title: Text(
          file.displayName,
          style: TextStyle(
            fontWeight: isCurrentFile ? FontWeight.bold : FontWeight.normal,
            color: isCurrentFile ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (file.relativePath != null && file.folderPath != '/')
              Text(
                file.folderPath,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            Text(
              '${file.sizeFormatted} • ${file.extension.toUpperCase()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
          onPressed: () => _playPause(context, file, allFiles, isPlaying),
        ),
        onTap: () => _playFile(context, file, allFiles),
      ),
    );
  }

  void _playFile(BuildContext context, MusicFile file, List<MusicFile> files) {
    final musicProvider = context.read<MusicPlayerProvider>();
    musicProvider.playFile(file, playlist: files);
  }

  void _playPause(BuildContext context, MusicFile file, List<MusicFile> files, bool isPlaying) {
    final musicProvider = context.read<MusicPlayerProvider>();
    
    if (musicProvider.currentFile?.url != file.url) {
      _playFile(context, file, files);
    } else {
      if (isPlaying) {
        musicProvider.pause();
      } else {
        musicProvider.play();
      }
    }
  }
}
