import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../bloc/bloc.dart';

/// Login Page following the exact stitch design (s_01_login_screen_new_style)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _storage = SecureStorageService();
  final _nipController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  String? _nipError;
  String? _passwordError;

  // Colors from stitch design
  static const Color _primary = Color(0xFF0040DF);
  static const Color _primaryContainer = Color(0xFF2D5BFF);
  static const Color _surface = Color(0xFFFAF8FF);
  static const Color _surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF434655);
  static const Color _outline = Color(0xFF737686);
  static const Color _outlineVariant = Color(0xFFC3C6D7);
  static const Color _tertiary = Color(0xFF7A1BC8);
  static const Color _error = Color(0xFFBA1A1A);

  @override
  void initState() {
    super.initState();
    _loadRememberedLogin();
  }

  @override
  void dispose() {
    _nipController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadRememberedLogin() async {
    if (!_storage.shouldRememberLogin()) return;

    final rememberedNip = _storage.getRememberedNip();
    final rememberedPassword = await _storage.getRememberedPassword();
    if (!mounted) return;

    setState(() {
      _rememberMe = true;
      _nipController.text = rememberedNip ?? '';
      _passwordController.text = rememberedPassword ?? '';
    });
  }

  Future<void> _saveRememberedLoginPreference() async {
    if (_rememberMe) {
      await _storage.saveRememberedLogin(
        nip: _nipController.text.trim(),
        password: _passwordController.text,
      );
      return;
    }

    await _storage.clearRememberedLogin();
  }

  bool _validate() {
    bool isValid = true;
    setState(() {
      if (_nipController.text.trim().isEmpty) {
        _nipError = 'NIP wajib diisi';
        isValid = false;
      } else if (_nipController.text.trim().length < 10) {
        _nipError = 'NIP tidak valid';
        isValid = false;
      } else {
        _nipError = null;
      }

      if (_passwordController.text.isEmpty) {
        _passwordError = 'Password wajib diisi';
        isValid = false;
      } else {
        _passwordError = null;
      }
    });
    return isValid;
  }

  Future<void> _handleLogin() async {
    if (_validate()) {
      if (!_rememberMe) {
        await _storage.clearRememberedLogin();
      }

      if (!mounted) return;

      context.read<AuthBloc>().add(
        AuthLoginRequested(
          nip: _nipController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            _saveRememberedLoginPreference();
          }

          if (state is AuthLoginFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: _error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        child: Stack(
          children: [
            // Background Organic Shapes
            _buildBackgroundShapes(),

            // Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Section
                        _buildLogoSection(),
                        const SizedBox(height: 48),

                        // Login Card (Glass)
                        _buildLoginCard(),
                        const SizedBox(height: 48),

                        // Footer
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundShapes() {
    return Stack(
      children: [
        // Top right organic shape (primary blue)
        Positioned(
          top: -150,
          right: -150,
          child: Container(
            width: 600,
            height: 600,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primaryContainer.withValues(alpha: 0.15),
                  _surface.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
        ),
        // Bottom left organic shape (tertiary purple)
        Positioned(
          bottom: -150,
          left: -150,
          child: Container(
            width: 500,
            height: 500,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _tertiary.withValues(alpha: 0.1),
                  _surface.withValues(alpha: 0),
                ],
                stops: const [0.0, 0.7],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // SMP Negeri 8 Pasuruan logo
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/logo_smpn8_pasuruan.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(height: 16),
        // App Name
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'SIM ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: _onSurface,
                ),
              ),
              TextSpan(
                text: 'PANLA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: _primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Digital Academy Ecosystem',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF131B2E).withValues(alpha: 0.06),
                blurRadius: 40,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Welcome Back',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter your credentials to access your dashboard.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: _onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // NIP Field
              _buildInputField(
                label: 'NIP (NOMOR INDUK PEGAWAI)',
                hint: 'e.g. 198106202009041003',
                controller: _nipController,
                icon: Icons.badge_outlined,
                error: _nipError,
                keyboardType: TextInputType.number,
                onChanged: (_) {
                  if (_nipError != null) setState(() => _nipError = null);
                },
              ),
              const SizedBox(height: 24),

              // Password Field
              _buildPasswordField(),
              const SizedBox(height: 24),

              // Remember Me
              _buildRememberMe(),
              const SizedBox(height: 24),

              // Login Button
              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    String? error,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: _onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _surfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: error != null ? Border.all(color: _error, width: 1) : null,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: GoogleFonts.inter(fontSize: 16, color: _onSurface),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(fontSize: 16, color: _outline),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(icon, color: _outline, size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 48),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              error,
              style: GoogleFonts.inter(fontSize: 12, color: _error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'PASSWORD',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: _onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _surfaceContainerHigh.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border: _passwordError != null
                ? Border.all(color: _error, width: 1)
                : null,
          ),
          child: TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            onChanged: (_) {
              if (_passwordError != null) setState(() => _passwordError = null);
            },
            style: GoogleFonts.inter(fontSize: 16, color: _onSurface),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: GoogleFonts.inter(fontSize: 16, color: _outline),
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 16, right: 12),
                child: Icon(Icons.lock_outline, color: _outline, size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 48),
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: _outline,
                    size: 20,
                  ),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(minWidth: 48),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (_passwordError != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              _passwordError!,
              style: GoogleFonts.inter(fontSize: 12, color: _error),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRememberMe() {
    return GestureDetector(
      onTap: () => setState(() => _rememberMe = !_rememberMe),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _rememberMe ? _primary : _surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
              border: _rememberMe
                  ? null
                  : Border.all(color: _outlineVariant, width: 1),
            ),
            child: _rememberMe
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            'Keep me logged in',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoginInProgress;

        return GestureDetector(
          onTap: isLoading ? null : _handleLogin,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_primary, _primaryContainer],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.2),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else ...[
                  Text(
                    'Masuk',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text.rich(
          TextSpan(
            text: 'Butuh bantuan? ',
            style: GoogleFonts.inter(fontSize: 14, color: _onSurfaceVariant),
            children: [
              TextSpan(
                text: 'Hubungi Admin',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 8,
          children: [
            _buildFooterLink('Privacy Policy'),
            _buildFooterDot(),
            _buildFooterLink('Terms of Service'),
            _buildFooterDot(),
            _buildFooterLink('Help Center'),
          ],
        ),
      ],
    );
  }

  Widget _buildFooterLink(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: _outline,
      ),
    );
  }

  Widget _buildFooterDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: 4,
        height: 4,
        decoration: const BoxDecoration(
          color: _outline,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
