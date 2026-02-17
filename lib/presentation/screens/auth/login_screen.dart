import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/extensions.dart';
import '../../providers/auth_provider.dart';

/// Login screen with email/password and Google Sign-In.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(currentUserProvider.notifier).signInWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(currentUserProvider.notifier).signInWithGoogle();
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(currentUserProvider.notifier).signInAsGuest();
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) context.showSnackBar(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F0F1E),
              Color(0xFF0A0A0F),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 60),

                // ── Logo & Title ─────────────────────────────────
                _buildLogo(),
                const SizedBox(height: 48),

                // ── Login Form ───────────────────────────────────
                _buildForm(),
                const SizedBox(height: 24),

                // ── Sign In Button ───────────────────────────────
                _buildSignInButton(),
                const SizedBox(height: 20),

                // ── Divider ──────────────────────────────────────
                _buildDivider(),
                const SizedBox(height: 20),

                // ── Google Sign In ───────────────────────────────
                _buildGoogleButton(),
                const SizedBox(height: 32),

                // ── Sign Up Link ─────────────────────────────────
                _buildSignUpLink(),
                const SizedBox(height: 24),

                // ── Guest Mode ───────────────────────────────────
                _buildGuestButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Glowing orb logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.premiumGradient,
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentPink.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome,
            color: Colors.white,
            size: 36,
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.5, 0.5),
              duration: 800.ms,
              curve: Curves.elasticOut,
            )
            .shimmer(delay: 800.ms, duration: 1200.ms),
        const SizedBox(height: 24),
        Text(
          'AI Muse',
          style: AppTheme.textTheme.displayLarge?.copyWith(
            letterSpacing: -1,
          ),
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
        const SizedBox(height: 8),
        Text(
          'Your AI Companion Experience',
          style: AppTheme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textGrey,
          ),
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: AppTheme.textTheme.bodyLarge,
            decoration: const InputDecoration(
              hintText: 'Email address',
              prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textGrey),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              if (!value.isValidEmail) return 'Enter a valid email';
              return null;
            },
          ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.1),
          const SizedBox(height: 16),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: AppTheme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: 'Password',
              prefixIcon:
                  const Icon(Icons.lock_outline, color: AppTheme.textGrey),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppTheme.textGrey,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Password is required';
              if (value.length < 6) return 'Password must be 6+ characters';
              return null;
            },
          ).animate().fadeIn(delay: 700.ms).slideX(begin: -0.1),
        ],
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleEmailLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.deepPurple,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Text('Sign In', style: TextStyle(fontSize: 16)),
      ),
    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppTheme.textGrey.withOpacity(0.2))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('or continue with',
              style: AppTheme.textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: AppTheme.textGrey.withOpacity(0.2))),
      ],
    ).animate().fadeIn(delay: 900.ms);
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleLogin,
        icon: const Icon(Icons.g_mobiledata, size: 28),
        label: const Text('Google'),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppTheme.textGrey.withOpacity(0.2)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: AppTheme.textWhite,
        ),
      ),
    ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1);
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Don't have an account? ",
            style: AppTheme.textTheme.bodyMedium),
        GestureDetector(
          onTap: () => context.push(AppRoutes.signup),
          child: Text(
            'Sign Up',
            style: AppTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.accentPink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 1100.ms);
  }

  Widget _buildGuestButton() {
    return TextButton(
      onPressed: _isLoading ? null : _handleGuestLogin,
      child: Text(
        'Try Demo (Guest Mode)',
        style: AppTheme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.textMuted,
          decoration: TextDecoration.underline,
        ),
      ),
    ).animate().fadeIn(delay: 1200.ms);
  }
}
