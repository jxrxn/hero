// lib/presentation/page/login_page.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/auth/auth_cubit.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  static const _bgAsset = 'assets/branding/onboarding_bg.png';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthCubit>().login(
            _emailCtrl.text.trim(),
            _passCtrl.text,
          );
      // Redirect till /home sköts av authStateChanges + go_router
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('Login misslyckades: $e'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onWhite = Colors.white.withValues(alpha: 0.92);
    final onWhiteSoft = Colors.white.withValues(alpha: 0.75);
    final outline = Colors.white.withValues(alpha: 0.20);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image (same as onboarding)
          Image.asset(
            LoginPage._bgAsset,
            fit: BoxFit.cover,
          ),

          // Vignette for readability
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: _GlassCard(
                    child: AutofillGroup(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Welcome back',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: onWhite,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Log in to continue.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: onWhiteSoft,
                                ),
                          ),
                          const SizedBox(height: 18),

                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            textInputAction: TextInputAction.next,
                            style: TextStyle(color: onWhite),
                            decoration: _inputDecoration(
                              label: 'Email',
                              icon: Icons.alternate_email,
                              outline: outline,
                              onWhite: onWhite,
                              onWhiteSoft: onWhiteSoft,
                            ),
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _passCtrl,
                            obscureText: true,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _loading ? null : _doLogin(),
                            style: TextStyle(color: onWhite),
                            decoration: _inputDecoration(
                              label: 'Password',
                              icon: Icons.lock_outline,
                              outline: outline,
                              onWhite: onWhite,
                              onWhiteSoft: onWhiteSoft,
                            ),
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _loading ? null : _doLogin,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.white.withValues(alpha: 0.14),
                                foregroundColor: onWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Log in'),
                            ),
                          ),

                          const SizedBox(height: 10),

                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _loading ? null : () => context.go('/signup'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: onWhite,
                                side: BorderSide(color: outline),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                backgroundColor: Colors.white.withValues(alpha: 0.05),
                              ),
                              child: const Text('Create account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    required Color outline,
    required Color onWhite,
    required Color onWhiteSoft,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: onWhiteSoft),
      prefixIcon: Icon(icon, color: onWhiteSoft),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.34)),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 26,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}