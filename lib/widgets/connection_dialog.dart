import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/webdav_provider.dart';
import '../models/music_models.dart';

class ConnectionDialog extends StatefulWidget {
  const ConnectionDialog({super.key});

  @override
  State<ConnectionDialog> createState() => _ConnectionDialogState();
}

class _ConnectionDialogState extends State<ConnectionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _basePathController = TextEditingController(text: '/');
  final _portController = TextEditingController(text: '80');
  final _maxDepthController = TextEditingController(text: '-1');
  
  bool _useHttps = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _loadExistingConnection();
  }

  void _loadExistingConnection() {
    final webdavProvider = context.read<WebDAVProvider>();
    final connection = webdavProvider.connection;
    
    if (connection != null) {
      _hostController.text = connection.host;
      _usernameController.text = connection.username;
      _passwordController.text = connection.password;
      _basePathController.text = connection.basePath;
      _portController.text = connection.port.toString();
      _maxDepthController.text = connection.maxScanDepth.toString();
      _useHttps = connection.useHttps;
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _basePathController.dispose();
    _portController.dispose();
    _maxDepthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('WebDAV 连接设置'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: '服务器地址',
                  hintText: 'example.com',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入服务器地址';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: '端口',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '请输入端口';
                        }
                        final port = int.tryParse(value);
                        if (port == null || port < 1 || port > 65535) {
                          return '端口范围：1-65535';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: SwitchListTile(
                      title: const Text('HTTPS'),
                      value: _useHttps,
                      onChanged: (value) {
                        setState(() {
                          _useHttps = value;
                          if (value) {
                            _portController.text = '443';
                          } else {
                            _portController.text = '80';
                          }
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: '用户名',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入用户名';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: '密码',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入密码';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _basePathController,
                decoration: const InputDecoration(
                  labelText: '基础路径',
                  hintText: '/music',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入基础路径';
                  }
                  if (!value.startsWith('/')) {
                    return '路径必须以 / 开头';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _maxDepthController,
                decoration: const InputDecoration(
                  labelText: '最大扫描深度',
                  hintText: '-1（无限制）',
                  border: OutlineInputBorder(),
                  helperText: '设置递归扫描的最大文件夹层数，-1表示无限制，0表示仅当前文件夹',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '请输入扫描深度';
                  }
                  final depth = int.tryParse(value);
                  if (depth == null || depth < -1) {
                    return '扫描深度必须 >= -1';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isConnecting ? null : () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        
        if (context.watch<WebDAVProvider>().isConnected)
          TextButton(
            onPressed: _isConnecting ? null : _disconnect,
            child: const Text('断开连接'),
          ),
        
        ElevatedButton(
          onPressed: _isConnecting ? null : _connect,
          child: _isConnecting 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('连接'),
        ),
      ],
    );
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isConnecting = true;
    });

    final connection = WebDAVConnection(
      host: _hostController.text.trim(),
      username: _usernameController.text.trim(),
      password: _passwordController.text,
      basePath: _basePathController.text.trim(),
      port: int.parse(_portController.text),
      useHttps: _useHttps,
      maxScanDepth: int.parse(_maxDepthController.text),
    );

    final webdavProvider = context.read<WebDAVProvider>();
    final success = await webdavProvider.connect(connection);

    setState(() {
      _isConnecting = false;
    });

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('连接成功')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(webdavProvider.error ?? '连接失败')),
      );
    }
  }

  void _disconnect() {
    final webdavProvider = context.read<WebDAVProvider>();
    webdavProvider.disconnect();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已断开连接')),
    );
  }
}
