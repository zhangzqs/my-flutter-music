/// 歌词自动滚动功能说明
/// 
/// 此文件描述了歌词显示组件的自动滚动功能特性

## 功能特性

### 🎯 居中显示
- 当前播放的歌词行始终位于屏幕正中心
- 使用精确的数学计算确保居中效果

### 🔄 自动滚动
- 根据音乐播放进度自动滚动歌词
- 平滑的动画过渡（600ms，easeInOut曲线）
- 智能检测歌词行变化，避免重复滚动

### 👆 用户交互
- 用户手动滚动时自动暂停自动滚动
- 3秒无操作后恢复自动滚动功能
- 保护用户的浏览体验

### 🎨 视觉效果
- 当前歌词行高亮显示（主题色、粗体、较大字体）
- 已播放歌词使用灰色显示
- 未播放歌词使用正常颜色显示
- 动画容器提供平滑的视觉过渡

### 📐 布局优化
- 上下增加100px padding，确保首尾歌词也能居中
- 每行歌词有充足的间距和内边距
- 响应式设计适应不同屏幕尺寸

### 🎵 中心指示线
- 可选的中心指示线帮助用户定位
- 渐变效果的半透明线条
- 不影响用户交互（IgnorePointer）

## 技术实现

### 核心算法
```dart
// 计算目标滚动位置
final double currentLineOffset = currentLineIndex * estimatedItemHeight;
final double targetOffset = currentLineOffset - (viewportHeight / 2) + (estimatedItemHeight / 2);
```

### 用户滚动检测
- 监听ScrollController的滚动事件
- 使用延迟机制检测用户停止滚动
- 状态管理防止冲突

### 性能优化
- 使用WidgetsBinding.instance.addPostFrameCallback确保在界面更新后执行
- 避免不必要的滚动动画
- 边界检测防止滚动越界

## 使用说明

1. 确保歌词数据已加载（LrcData）
2. 音乐播放器需要提供currentLyricLineIndex
3. 组件会自动处理所有滚动逻辑
4. 用户可以随时手动滚动查看其他歌词
