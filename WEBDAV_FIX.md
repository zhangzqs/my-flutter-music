# WebDAV URL 路径重复问题修复

## 问题描述
用户设置basePath为`/disk-4t`，但实际访问的URL变成了`/disk-4t/disk-4t/`，出现了路径重复的问题。

## 问题原因
1. `WebDAVConnection.serverUrl`已经包含了basePath
2. 在WebDAV客户端连接和文件请求时，又额外添加了路径，导致重复

## 修复方案

### 1. 修改WebDAVConnection模型
```dart
// 原来的 serverUrl 包含 basePath
String get serverUrl {
  return '$protocol://$host$portStr$basePath';
}

// 修复后：分离服务器URL和完整URL
String get serverUrl {
  return '$protocol://$host$portStr';  // 不包含basePath
}

String get baseUrl {
  return '$protocol://$host$portStr$basePath';  // 包含basePath用于WebDAV连接
}
```

### 2. 修改WebDAV Provider连接逻辑
```dart
// 使用baseUrl进行WebDAV连接
final client = webdav.newClient(
  connection.baseUrl,  // 包含basePath
  user: connection.username,
  password: connection.password,
);

// 设置当前路径为根路径，因为baseUrl已经包含basePath
_currentPath = '/';
```

### 3. 修改文件加载逻辑
```dart
// 路径规范化，避免重复添加basePath
final normalizedPath = targetPath.startsWith('/') ? targetPath : '/$targetPath';
final files = await _client!.readDir(normalizedPath);
```

### 4. 添加调试日志
增加详细的调试输出，帮助诊断URL构建问题：
- 连接详情（主机、端口、basePath等）
- 请求路径信息
- 最终的请求URL

## 测试验证
修复后，当用户设置basePath为`/disk-4t`时：
- WebDAV连接URL: `http://host:port/disk-4t`
- 文件列表请求: `PROPFIND /disk-4t/` (而不是`/disk-4t/disk-4t/`)
- 文件播放URL: `http://host:port/完整文件路径`

## 相关文件
- `lib/models/music_models.dart` - WebDAVConnection模型
- `lib/providers/webdav_provider.dart` - WebDAV连接和文件操作逻辑

这个修复确保了URL路径的正确构建，解决了basePath重复的问题。
