import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text.trim();

      final endpoint = _isLogin ? 'auth/login' : 'auth/register';
      final url = Uri.parse('${AppConfig.apiBaseUrl}/$endpoint');

      final body = <String, String>{
        'username': username,
        'password': password,
      };
      if (!_isLogin) body['email'] = _emailController.text.trim();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          await auth.login(
            accountId: (data['data']['id'] ?? data['id'] ?? 1) as int,
            username: username,
            token: data['token'] ?? 'dev-token',
          );
          Navigator.of(context).pushReplacementNamed('/character-select');
        }
      } else {
        final err = jsonDecode(response.body);
        _errorMessage = (err['message'] ?? err['error'] ?? '请求失败').toString();
      }
    } catch (e) {
      _errorMessage = '连接失败: ${e.toString().split('\n').first}';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context, listen: false);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF16213e), Color(0xFF0f3460), Color(0xFF533483)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    '✨ 冒险岛 079 ✨',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? '登录账号' : '注册新账号',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: '用户名',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person, color: Colors.amber),
                          ),
                          validator: (v) =>
                              (v == null || v.length < 3) ? '用户名至少 3 个字符' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: '密码',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock, color: Colors.amber),
                          ),
                          validator: (v) =>
                              (v == null || v.length < 6) ? '密码至少 6 个字符' : null,
                        ),
                        if (!_isLogin) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: '邮箱 (可选)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email, color: Colors.amber),
                            ),
                          ),
                        ],
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : Text(_isLogin ? '登录冒险' : '创建账号'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                            });
                          },
                          child: Text(
                            _isLogin ? '还没有账号? 去注册 →' : '已有账号? 去登录 →',
                            style: const TextStyle(color: Colors.amber),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '服务器: ${game.serverStatus}',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
