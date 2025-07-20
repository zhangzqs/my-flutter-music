import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/webdav_provider.dart';
import '../providers/music_player_provider.dart';
import '../widgets/connection_dialog.dart';
import '../widgets/music_list.dart';
import '../widgets/player_controls.dart';
import '../widgets/lyrics_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // 设置WebDAV凭据更新回调
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final webdavProvider = context.read<WebDAVProvider>();
      final musicProvider = context.read<MusicPlayerProvider>();
      webdavProvider.setCredentialsUpdateCallback((serverUrl, username, password) {
        musicProvider.setWebDAVCredentials(serverUrl, username, password);
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Music'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.library_music),
              text: '音乐列表',
            ),
            Tab(
              icon: Icon(Icons.lyrics),
              text: '歌词',
            ),
          ],
        ),
        actions: [
          Consumer<WebDAVProvider>(
            builder: (context, webdavProvider, child) {
              return IconButton(
                icon: Icon(webdavProvider.isConnected ? Icons.cloud_done : Icons.cloud_off),
                onPressed: () => _showConnectionDialog(context),
                tooltip: webdavProvider.isConnected ? '已连接' : '未连接',
              );
            },
          ),
          Consumer<WebDAVProvider>(
            builder: (context, webdavProvider, child) {
              if (!webdavProvider.isConnected) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => webdavProvider.refresh(),
                tooltip: '刷新',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 错误消息显示
          Consumer<WebDAVProvider>(
            builder: (context, webdavProvider, child) {
              if (webdavProvider.error != null) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Row(
                    children: [
                      Icon(
                        Icons.error,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          webdavProvider.error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          // 这里可以添加清除错误的方法
                        },
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          
          // 加载指示器
          Consumer<WebDAVProvider>(
            builder: (context, webdavProvider, child) {
              if (webdavProvider.isLoading) {
                return const LinearProgressIndicator();
              }
              return const SizedBox.shrink();
            },
          ),

          // 主要内容区域
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 音乐列表标签页
                Consumer<WebDAVProvider>(
                  builder: (context, webdavProvider, child) {
                    if (!webdavProvider.isConnected) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_off,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '未连接到WebDAV服务器',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '点击右上角的图标配置连接',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _showConnectionDialog(context),
                              icon: const Icon(Icons.settings),
                              label: const Text('配置连接'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (webdavProvider.musicFiles.isEmpty && !webdavProvider.isLoading) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_off,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '没有找到音乐文件',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '当前目录下没有支持的音频文件',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return const MusicList();
                  },
                ),
                
                // 歌词标签页
                const LyricsDisplay(),
              ],
            ),
          ),
        ],
      ),
      
      // 底部播放器控制条
      bottomNavigationBar: const PlayerControls(),
    );
  }

  void _showConnectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ConnectionDialog(),
    );
  }
}
