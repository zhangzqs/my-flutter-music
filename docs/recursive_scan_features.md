# 🔍 WebDAV 递归音乐扫描功能

## 功能概述
为 WebDAV 音乐播放器添加了强大的递归扫描功能，能够自动扫描服务器上多层文件夹中的所有音乐文件。

## ✨ 主要特性

### 🗂️ 递归文件夹扫描
- **深度扫描**: 自动遍历所有子文件夹和子子文件夹
- **智能过滤**: 自动跳过系统文件夹（.、Trash、RecycleBin、@eaDir）
- **实时进度**: 显示扫描进度和找到的文件数量
- **容错处理**: 单个文件夹错误不会中断整个扫描过程

### 📱 用户界面优化
- **扫描按钮**: 显眼的"递归扫描"按钮
- **进度显示**: 实时显示扫描状态和进度
- **分组显示**: 按文件夹路径分组展示音乐文件
- **路径信息**: 显示每个文件的完整路径信息

### 📂 文件夹分组
- **层级显示**: 按文件夹结构分组显示音乐文件
- **文件夹标题**: 清晰显示文件夹路径和文件数量
- **相对路径**: 保存并显示文件的相对路径信息

## 🛠️ 技术实现

### 核心组件更新

#### 1. WebDAVProvider 增强
```dart
// 新增递归扫描方法
Future<void> scanAllMusicFiles([String? startPath])

// 递归扫描单个文件夹
Future<void> _recursiveScanFolder(String folderPath, List<MusicFile> musicFiles)

// 扫描状态管理
bool _isRecursiveScanning
int _totalFoldersScanned
int _totalMusicFilesFound
String _currentScanningFolder
```

#### 2. MusicFile 模型扩展
```dart
// 新增相对路径字段
final String? relativePath

// 新增文件夹路径获取方法
String get folderPath
String get fullDisplayPath
```

#### 3. MusicList UI 重构
- 递归扫描控制界面
- 实时进度显示
- 按文件夹分组的列表显示
- 文件路径信息展示

### 关键算法

#### 递归扫描算法
1. 从指定起始路径开始扫描
2. 读取当前文件夹内容
3. 处理音乐文件并添加到结果列表
4. 递归处理所有子文件夹
5. 更新扫描进度和统计信息

#### 文件夹分组算法
1. 从文件的相对路径提取文件夹路径
2. 按文件夹路径对文件进行分组
3. 对文件夹进行排序
4. 生成分组显示界面

## 🎵 使用方法

### 开始递归扫描
1. 连接到 WebDAV 服务器
2. 点击"递归扫描"按钮
3. 等待扫描完成
4. 查看按文件夹分组的音乐文件

### 扫描进度监控
- **实时状态**: 显示当前正在扫描的文件夹
- **统计信息**: 显示已扫描文件夹数量和找到的音乐文件数量
- **进度指示**: 扫描按钮显示进度指示器

### 文件浏览
- **分组显示**: 音乐文件按所在文件夹分组
- **路径信息**: 每个文件显示其相对路径
- **快速播放**: 点击文件直接播放

## 🔧 配置选项

### 支持的音乐格式
- MP3 (.mp3)
- M4A (.m4a)  
- AAC (.aac)
- FLAC (.flac)
- WAV (.wav)
- OGG (.ogg)

### 跳过的文件夹
- 隐藏文件夹（以 . 开头）
- 系统垃圾箱（Trash、RecycleBin）
- NAS 系统文件夹（@eaDir）

## 📊 性能特性

### 优化策略
- **异步处理**: 不阻塞 UI 线程
- **错误隔离**: 单个文件夹错误不影响整体扫描
- **内存管理**: 增量添加文件，避免内存峰值
- **网络优化**: 合理的请求频率控制

### 扫描效率
- **智能跳过**: 自动跳过系统和隐藏文件夹
- **并发控制**: 避免过多并发请求
- **进度反馈**: 实时用户体验

## 🚀 使用示例

```dart
// 开始递归扫描
await webdavProvider.scanAllMusicFiles();

// 获取扫描结果
final musicFiles = webdavProvider.musicFiles;

// 按文件夹分组
final groupedFiles = <String, List<MusicFile>>{};
for (final file in musicFiles) {
  final folderPath = file.folderPath;
  groupedFiles.putIfAbsent(folderPath, () => []).add(file);
}
```

## 🎯 使用场景

### 适用场景
- **大型音乐库**: 音乐文件分散在多个文件夹中
- **分类管理**: 按艺术家、专辑、类型等文件夹组织
- **NAS 存储**: 网络附加存储设备上的音乐库
- **云存储**: WebDAV 协议的云存储服务

### 优势
- **一键扫描**: 无需手动浏览每个文件夹
- **完整发现**: 找到所有层级的音乐文件
- **结构保持**: 保留原有的文件夹组织结构
- **高效浏览**: 分组显示便于管理和播放

这个递归扫描功能大大提升了音乐库的管理效率，特别适合有复杂文件夹结构的音乐收藏！
