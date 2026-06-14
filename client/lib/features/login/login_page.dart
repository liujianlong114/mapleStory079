import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/game_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  late final AnimationController _errorAnimController;
  late final Animation<double> _errorBlink;

  @override
  void initState() {
    super.initState();
    _errorAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _errorBlink = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _errorAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _registerUsernameController.dispose();
    _registerPasswordController.dispose();
    _confirmPasswordController.dispose();
    _errorAnimController.dispose();
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
          Navigator.of(context).pushReplacementNamed('/character-select');
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
            _errorMessage = null;
          });
        } else {
          _errorMessage = auth.errorMessage ?? '注册失败';
        }
      }
    } catch (e) {
      _errorMessage = '连接失败: ${e.toString().split('\n').first}';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0B1A3A),
              Color(0xFF2B1B5C),
              Color(0xFF0A0A1F),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: Column(
              children: [
                const SizedBox(height: 36),
                _buildTitle(),
                const SizedBox(height: 20),
                Expanded(child: _buildFormPanel()),
                const SizedBox(height: 12),
                _buildBottomButtons(),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Text(
                      AppConfig.version,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF3B2414),
        border: Border.all(color: const Color(0xFFD4A373), width: 3),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.landscape, color: AppTheme.gold, size: 36),
          const SizedBox(width: 12),
          Text(
            AppConfig.appName,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFB13A),
              letterSpacing: 2.0,
              shadows: [
                const Shadow(
                  color: Color(0xFF8B0000),
                  blurRadius: 2,
                  offset: Offset(2, 2),
                ),
                Shadow(
                  color: Colors.black.withOpacity(0.6),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.landscape, color: AppTheme.gold, size: 36),
        ],
      ),
    );
  }

  Widget _buildFormPanel() {
    return Center(
      child: Container(
        width: 440,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B3A).withOpacity(0.85),
          border: Border.all(color: const Color(0xFFD4A373), width: 3),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildModeTab(label: '登录', selected: _isLogin, onTap: _toggleMode),
                const SizedBox(width: 12),
                _buildModeTab(
                  label: '注册',
                  selected: !_isLogin,
                  onTap: _toggleMode,
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (_isLogin) ...[
              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: Color(0xFF1C1C1C)),
                decoration: AppTheme.mapleInputDecoration('账号', Icons.person),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: const TextStyle(color: Color(0xFF1C1C1C)),
                decoration: AppTheme.mapleInputDecoration('密码', Icons.lock),
              ),
            ] else ...[
              TextFormField(
                controller: _registerUsernameController,
                style: const TextStyle(color: Color(0xFF1C1C1C)),
                decoration: AppTheme.mapleInputDecoration('新账号', Icons.person_add),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _registerPasswordController,
                obscureText: true,
                style: const TextStyle(color: Color(0xFF1C1C1C)),
                decoration: AppTheme.mapleInputDecoration('密码', Icons.lock),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: true,
                style: const TextStyle(color: Color(0xFF1C1C1C)),
                decoration: AppTheme.mapleInputDecoration('确认密码', Icons.lock_outline),
              ),
            ],
            const SizedBox(height: 12),
            _buildErrorText(),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _MapleButton(
                    label: _isLogin ? '登录' : '注册',
                    onPressed: _isLoading ? null : _submit,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF4A460), Color(0xFFD2691E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    isLoading: _isLoading,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MapleButton(
                    label: _isLogin ? '注册账号' : '回到登录',
                    onPressed: _isLoading ? null : _toggleMode,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4A4A4A), Color(0xFF2C2C2C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '服务器状态: ${Provider.of<GameProvider>(context, listen: false).serverStatus}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFD2691E)
              : const Color(0xFF3B2414).withOpacity(0.6),
          border: Border.all(
            color: const Color(0xFFD4A373),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorText() {
    if (_errorMessage == null) {
      return const SizedBox(height: 24);
    }
    return SizedBox(
      height: 24,
      child: AnimatedBuilder(
        animation: _errorBlink,
        builder: (_, __) {
          return Text(
            _errorMessage!,
            style: TextStyle(
              color: Colors.redAccent.withOpacity(_errorBlink.value),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
            textAlign: TextAlign.center,
          );
        },
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildCircleButton(Icons.settings, '设置'),
          const SizedBox(width: 18),
          _buildCircleButton(Icons.help_outline, '帮助'),
          const SizedBox(width: 18),
          _buildCircleButton(Icons.language, '网站'),
          const SizedBox(width: 18),
          _buildCircleButton(Icons.exit_to_app, '退出'),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A3B2A), Color(0xFF2B1B5C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: const Color(0xFFD4A373), width: 2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(icon, color: AppTheme.gold, size: 20),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _MapleButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final bool isLoading;

  const _MapleButton({
    required this.label,
    required this.onPressed,
    required this.gradient,
    this.isLoading = false,
  });

  @override
  State<_MapleButton> createState() => _MapleButtonState();
}

class _MapleButtonState extends State<_MapleButton>
    with SingleTickerProviderStateMixin {
  double _translateY = 0;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return MouseRegion(
      onEnter: (_) => setState(() => _translateY = -2),
      onExit: (_) => setState(() => _translateY = 0),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          transform: Matrix4.translationValues(0, _translateY, 0),
          height: 46,
          decoration: BoxDecoration(
            gradient: disabled
                ? const LinearGradient(
                    colors: [Color(0xFF7A7A7A), Color(0xFF5A5A5A)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : widget.gradient,
            border: Border.all(
              color: const Color(0xFF3B2414),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: disabled ? 1 : 6,
                offset: Offset(0, disabled ? 1 : _translateY.abs() + 3),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 1,
                          offset: Offset(1, 1),
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
