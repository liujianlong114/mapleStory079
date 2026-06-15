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
          AudioManager().playUiClick();
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
          AudioManager().playUiClick();
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
      AudioManager().playUiClick();
      _submit();
    } else if (id == 'quit') {
      AudioManager().playUiClick();
      AudioManager().stopBgm();
    }
  }

  InputDecoration _bareInput(String hint) => InputDecoration(
        isDense: true,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF666666), fontSize: 12),
        filled: true,
        fillColor: const Color(0xFFE8E0D0),
        contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      );

  @override
  Widget build(BuildContext context) {
    if (_scene == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFFFB13A))),
      );
    }

    final panel = _scene!.loginPanel ?? const WzRect(x: 279, y: 352, w: 200, h: 80);

    return Scaffold(
      body: Stack(
        children: [
          WzSceneScreen(
            manifest: _scene!,
            onButton: _onSceneButton,
            overlay: Stack(
              children: [
                WzLoginPanel(
                  panel: panel,
                  panelImage: _scene!.panelImage,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        top: 0,
                        right: 0,
                        height: 22,
                        child: TextField(
                          controller: _isLogin ? _usernameController : _registerUsernameController,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A), height: 1.1),
                          decoration: _bareInput(_isLogin ? '账号' : '新账号'),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: 30,
                        right: 0,
                        height: 22,
                        child: TextField(
                          controller: _isLogin ? _passwordController : _registerPasswordController,
                          obscureText: true,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A), height: 1.1),
                          decoration: _bareInput('密码'),
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                      if (!_isLogin)
                        Positioned(
                          left: 0,
                          top: 60,
                          right: 0,
                          height: 22,
                          child: TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A), height: 1.1),
                            decoration: _bareInput('确认密码'),
                          ),
                        ),
                      if (_errorMessage != null)
                        Positioned(
                          left: 12,
                          right: 12,
                          bottom: 28,
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Color(0xFFFF5252), fontSize: 10),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                          ),
                        ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 8,
                        child: GestureDetector(
                          onTap: _isLoading
                              ? null
                              : () {
                                  AudioManager().playUiClick();
                                  setState(() => _isLogin = !_isLogin);
                                },
                          child: Text(
                            _isLogin ? '注册新账号' : '返回登录',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 10,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoading)
                  const ColoredBox(
                    color: Colors.black26,
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFFFB13A))),
                  ),
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
