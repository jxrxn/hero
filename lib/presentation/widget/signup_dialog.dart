// lib/presentation/widget/signup_dialog.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth/auth_cubit.dart';
import '../cubit/auth/auth_state.dart';

class SignupDialog extends StatefulWidget {
  const SignupDialog({super.key});

  @override
  State<SignupDialog> createState() => _SignupDialogState();
}

class _SignupDialogState extends State<SignupDialog> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _doSignup(bool loading) async {
    if (loading) return;

    await context.read<AuthCubit>().signUp(
          _emailCtrl.text.trim(),
          _passCtrl.text,
        );

    // Om signup lyckas blir man ofta inloggad -> redirect sköts av router.
    // Stäng dialogen när anropet är klart.
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                // “Glass”: transparent vit istället för grön tint
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.18),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 28,
                    spreadRadius: 0,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
                child: BlocBuilder<AuthCubit, AuthState>(
                  buildWhen: (p, c) => p.status != c.status,
                  builder: (context, state) {
                    final loading = state.status == AuthStatus.loading;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header (centrerad, close uppe till höger)
                        Stack(
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Text(
                                    'Create account',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Create a new account to start building your crew.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: scheme.onSurface
                                              .withValues(alpha: 0.72),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              right: 0,
                              top: 0,
                              child: IconButton(
                                tooltip: 'Close',
                                onPressed:
                                    loading ? null : () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: InputDecoration(
                            labelText: 'Email',
                            prefixIcon: const Icon(Icons.alternate_email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        TextField(
                          controller: _passCtrl,
                          obscureText: true,
                          autofillHints: const [AutofillHints.newPassword],
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: FilledButton(
                            onPressed: loading ? null : () => _doSignup(loading),
                            child: Text(loading ? '...' : 'Create account'),
                          ),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed:
                                loading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Visar signup-dialogen med blur utan extra mörk overlay.
/// (Viktigt för att bakgrundsbilden ska se likadan ut som på login.)
Future<void> showSignupDialog(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Create account',
    barrierColor: Colors.transparent, // ✅ ingen extra “mörkläggning”
    pageBuilder: (context, anim1, anim2) {
      // Lätt blur över hela skärmen, men utan färg/tint.
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: const Center(child: SignupDialog()),
      );
    },
    transitionBuilder: (context, anim, secondaryAnim, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 180),
  );
}