# My Music - WebDAV音乐播放器 (Windows版)

## 快速开始

### 1. 环境准备
确保已安装：
- Flutter SDK (3.8.1+)
- Visual Studio 2022 (包含C++桌面开发工具)
- Windows 10/11

### 2. 运行应用
双击 `run_windows.bat` 或在命令行执行：
```
flutter run -d windows
```

### 3. 构建发布版本
双击 `build_windows.bat` 或在命令行执行：
```
flutter build windows --release
```

## 使用步骤

### 连接WebDAV服务器
1. 启动应用后，点击右上角的云图标
2. 填写连接信息：
   - **服务器地址**: 如 `192.168.1.100` 或 `myserver.com`
   - **端口**: HTTP通常为80，HTTPS为443
   - **用户名/密码**: WebDAV账户信息
   - **基础路径**: 音乐文件夹路径，如 `/music` 或 `/`
   - **HTTPS**: 是否使用安全连接

### 播放音乐
1. 连接成功后会自动显示音乐文件列表
2. 点击任意音乐文件开始播放
3. 使用底部播放控制条：
   - 播放/暂停
   - 上一首/下一首
   - 进度拖拽
   - 随机/重复播放

## 支持的格式
- MP3
- M4A
- AAC
- FLAC
- WAV
- OGG

## 常见WebDAV服务器配置

### Nextcloud
- 地址: `your-domain.com`
- 端口: `443` (HTTPS)
- 路径: `/remote.php/dav/files/用户名/`

### Synology NAS
- 地址: `NAS的IP地址`
- 端口: `5006` (HTTP) 或 `5007` (HTTPS)
- 路径: `/music/` (根据共享文件夹设置)

### Apache配置示例
```apache
LoadModule dav_module modules/mod_dav.so
LoadModule dav_fs_module modules/mod_dav_fs.so

<Directory "/path/to/music">
    DAV On
    AuthType Basic
    AuthName "WebDAV Music"
    AuthUserFile /path/to/.htpasswd
    Require valid-user
</Directory>
```

## 故障排除

### 连接失败
- 检查服务器地址和端口
- 确认防火墙设置
- 验证用户名密码
- 测试WebDAV服务是否正常

### 无音乐文件
- 检查路径设置
- 确认文件格式支持
- 验证文件权限

### 播放问题
- 检查网络连接
- 确认音频驱动正常
- 重启应用尝试

## 技术支持
如有问题，请检查：
1. Flutter环境是否正确配置
2. Windows开发环境是否完整
3. WebDAV服务器是否正常运行
