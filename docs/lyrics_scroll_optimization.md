/// 歌词滚动优化说明
/// 
/// 本次更新针对歌词自动滚动中心定位问题进行了全面优化

## 🎯 主要问题解决

### 问题描述
- 高亮的歌词框不能始终保持在屏幕中心
- 滚动位置计算不准确
- 动态字体大小导致布局计算偏差

### 解决方案

#### 1. 统一字体大小
```dart
// 修改前：动态字体大小
fontSize: isCurrentLine ? 20 : 16

// 修改后：统一字体大小
fontSize: 18 // 所有歌词行使用相同字体大小
```
**优势**: 确保每行高度一致，便于精确计算滚动位置

#### 2. 精确高度计算
```dart
// 每行精确尺寸计算
const double itemVerticalPadding = 12.0 * 2; // 上下padding
const double itemVerticalMargin = 4.0 * 2;   // 上下margin
const double fontSize = 18.0; // 统一字体大小
const double lineHeight = 1.5; // CSS line-height
const double textHeight = fontSize * lineHeight;
const double totalItemHeight = itemVerticalPadding + itemVerticalMargin + textHeight;
```

#### 3. 中心对齐算法
```dart
// 计算当前行的绝对位置
final double currentItemTop = listPadding + (lineIndex * totalItemHeight);

// 计算行中心位置
final double itemCenter = currentItemTop + (totalItemHeight / 2);
final double viewportCenter = viewportHeight / 2;

// 计算滚动偏移量，使行中心对齐视口中心
final double targetScrollOffset = itemCenter - viewportCenter;
```

#### 4. 增强的中心指示线
- 更明显的视觉效果
- 渐变色彩和阴影
- 帮助确认中心对齐效果

## 🔧 技术改进

### 滚动性能优化
- 使用`Curves.easeOutCubic`缓动曲线
- 500ms滚动持续时间（更流畅）
- PostFrameCallback确保UI渲染完成后再滚动

### 调试信息
添加详细的滚动计算日志：
```dart
debugPrint('滚动计算详情:');
debugPrint('  行索引: $lineIndex');
debugPrint('  单行高度: ${totalItemHeight.toStringAsFixed(1)}px');
debugPrint('  行顶部位置: ${currentItemTop.toStringAsFixed(1)}px');
debugPrint('  行中心位置: ${itemCenter.toStringAsFixed(1)}px');
debugPrint('  视口中心: ${viewportCenter.toStringAsFixed(1)}px');
debugPrint('  目标滚动偏移: ${targetScrollOffset.toStringAsFixed(1)}px');
debugPrint('  最终滚动偏移: ${clampedOffset.toStringAsFixed(1)}px');
```

### 用户交互保护
- 检测用户手动滚动
- 3秒延迟后恢复自动滚动
- 避免自动滚动与用户操作冲突

## 🎵 视觉效果提升

### 高亮样式
- 保持原有的边框和背景色
- 统一字体大小但保持粗体效果
- 颜色渐变仍然区分已播放、当前、未播放状态

### 中心指示线
- 3px高度的渐变线条
- 主题色彩匹配
- 半透明效果不干扰阅读
- 圆角和阴影增强立体感

## 📱 使用体验

### 期望效果
1. **精确居中**: 当前播放的歌词始终位于屏幕正中心
2. **平滑过渡**: 歌词切换时平滑滚动到新位置
3. **用户友好**: 手动滚动时自动暂停，停止操作后恢复
4. **视觉清晰**: 中心指示线帮助用户了解焦点位置

### 测试方法
1. 播放有歌词的音乐
2. 观察当前播放歌词是否始终在屏幕中心
3. 检查中心指示线是否穿过当前高亮的歌词
4. 测试手动滚动后是否能正确恢复自动滚动

## 🚀 后续优化空间

### 可能的进一步改进
1. **动态高度检测**: 实时测量实际渲染高度
2. **智能预测**: 根据歌词内容长度调整滚动时机
3. **自适应速度**: 根据歌词切换频率调整滚动速度
4. **多语言适配**: 考虑不同语言文字的行高差异

这次优化应该能够显著改善歌词滚动的中心定位问题，确保用户体验的流畅性和准确性。
