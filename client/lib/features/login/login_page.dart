import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../core/resources/assets.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';
import '../maple/wz_scene.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  WzSceneManifest? _scene;
  final _usernameController = TextEditingController(text: 'test');
  final _passwordController = TextEditingController(text: 'test123456');
  final _registerUsernameController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WzSceneManifest.load('assets/scenes/login_title.json').then((m) {
      if (mounted) setState(() => _scene = m);
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _registerUsernameController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (_isLogin) {
        final username = _usernameController.text.trim();
        final password = _passwordController.text.trim();
        if (username.isEmpty || password.isEmpty) {
          _errorMessage = '请输入账号和密码';
          return;
        }
        final ok = await auth.loginByCredentials(username, password);
        if (ok && mounted) {
          _navigateAfterLogin(auth);
        } else {
          _errorMessage = auth.errorMessage ?? '登录失败';
        }
      } else {
        final username = _registerUsernameController.text.trim();
        final password = _registerPasswordController.text.trim();
        final confirm = _confirmPasswordController.text.trim();
        if (username.length < 3) {
          _errorMessage = '用户名至少 3 个字符';
          return;
        }
        if (password.length < 6) {
          _errorMessage = '密码至少 6 个字符';
          return;
        }
        if (password != confirm) {
          _errorMessage = '两次输入的密码不一致';
          return;
        }
        final ok = await auth.register(username, password, '');
        if (ok && mounted) {
          setState(() {
            _isLogin = true;
            _registerUsernameController.clear();
            _registerPasswordController.clear();
            _confirmPasswordController.clear();
            _usernameController.text = username;
          });
        } else {
          _errorMessage = auth.errorMessage ?? '注册失败';
        }
      }
    } catch (e) {
      _errorMessage = e.toString().split('\n').first;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateAfterLogin(AuthProvider auth) {
    if (auth.needsGender) {
      Navigator.of(context).pushReplacementNamed('/gender');
    } else {
      Navigator.of(context).pushReplacementNamed('/world-select');
    }
  }

  void _onSceneButton(String id) {
    if (id == 'login') {
      _submit();
    } else if (id == 'quit') {
      AudioManager().stopBgm();
    }
  }

  InputDecoration _input(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF888888), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFF5F0E0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF5D3A1A), width: 2),
          borderRadius: BorderRadius.circular(3),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF5D3A1A), width: 2),
          borderRadius: BorderRadius.circular(3),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_scene == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFB13A))),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          WzSceneScreen(
            manifest: _scene!,
            onButton: _onSceneButton,
            overlay: Stack(
              children: [
                WzLoginPanel(
                  panel: _scene!.loginPanel,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isLogin ? '账号登录' : '注册账号',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFE082),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isLogin) ...[
                        TextField(
                          controller: _usernameController,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1C)),
                          decoration: _input('账号'),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1C)),
                          decoration: _input('密码'),
                          onSubmitted: (_) => _submit(),
                        ),
                      ] else ...[
                        TextField(
                          controller: _registerUsernameController,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1C)),
                          decoration: _input('新账号'),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _registerPasswordController,
                          obscureText: true,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1C)),
                          decoration: _input('密码'),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF1C1C1C)),
                          decoration: _input('确认密码'),
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: _isLoading ? null : () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? '注册新账号' : '返回登录',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  Container(color: Colors.black26, child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFFB13A)),
                  )),
              ],
            ),
          ),
          Positioned(
            right: 12,
            bottom: 8,
            child: Text(
              '${AppConfig.version} | ${Provider.of<GameProvider>(context, listen: false).serverStatus}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
