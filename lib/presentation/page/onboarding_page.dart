// lib/presentation/page/onboarding_page.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubit/onboarding/onboarding_cubit.dart';
import '../cubit/onboarding/onboarding_state.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  static const _bgAsset = 'assets/branding/onboarding_bg.png';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        if (!state.hydrated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final cubit = context.read<OnboardingCubit>();
        final step = state.step.clamp(0, 2);

        Widget content;
        if (step == 0) {
          content = _Intro(onNext: cubit.next);
        } else if (step == 1) {
          content = _ConsentStep(
            progressLabel: 'Step 2 of 3',
            title: 'Analytics',
            question: 'Allow HeroDex to collect anonymous usage data (Analytics)?',
            value: state.analyticsEnabled,
            onChanged: cubit.setAnalytics,
            onBack: cubit.back,
            onNext: cubit.next,
            nextLabel: 'Next',
          );
        } else {
          content = _ConsentStep(
            progressLabel: 'Step 3 of 3',
            title: 'Crashlytics',
            question: 'Allow HeroDex to collect crash reports to improve stability?',
            value: state.crashlyticsEnabled,
            onChanged: cubit.setCrashlytics,
            onBack: cubit.back,
            onNext: () async {
              await cubit.finish();
              if (!context.mounted) return;
              context.go('/login');
            },
            nextLabel: 'Finish',
          );
        }

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Background image
              Image.asset(
                _bgAsset,
                fit: BoxFit.cover,
              ),

              // Dark vignette for readability
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Colors.black.withValues(alpha: 0.20),
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
                    child: _GlassCard(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        transitionBuilder: (child, anim) {
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.02),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          );
                        },
                        child: KeyedSubtree(
                          key: ValueKey(step),
                          child: content,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Samma höjd/placering oavsett steg:
    // - minHeight låser layouten
    // - maxWidth håller det snyggt på desktop
    const minH = 310.0;

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 560,
        minHeight: minH,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08), // ✅ transparent vit
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
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final onWhite = Colors.white.withValues(alpha: 0.92);
    final onWhiteSoft = Colors.white.withValues(alpha: 0.75);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'The world runs on balance',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: onWhite,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 14),
        Text(
          'Heroes and Villains shape reality through conflict.\n'
          'Too much power on one side, and the system destabilizes.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: onWhiteSoft,
                height: 1.35,
              ),
        ),
        const SizedBox(height: 14),
        Text(
          'Your mission is simple: maintain the balance.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: onWhite,
                height: 1.35,
              ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onNext,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              foregroundColor: Colors.white.withValues(alpha: 0.92),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Continue'),
          ),
        ),
      ],
    );
  }
}

class _ConsentStep extends StatelessWidget {
  const _ConsentStep({
    required this.progressLabel,
    required this.title,
    required this.question,
    required this.value,
    required this.onChanged,
    required this.onBack,
    required this.onNext,
    required this.nextLabel,
  });

  final String progressLabel;
  final String title;
  final String question;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final String nextLabel;

  @override
  Widget build(BuildContext context) {
    final onWhite = Colors.white.withValues(alpha: 0.92);
    final onWhiteSoft = Colors.white.withValues(alpha: 0.75);
    final outline = Colors.white.withValues(alpha: 0.22);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          progressLabel,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: onWhiteSoft,
              ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: onWhite,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),
        Text(
          question,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: onWhiteSoft,
                height: 1.35,
              ),
        ),
        const SizedBox(height: 16),

        // Yes / No segment
        Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  outline: outline,
                ),
          ),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Yes')),
              ButtonSegment(value: false, label: Text('No')),
            ],
            selected: {value},
            onSelectionChanged: (set) {
              if (set.isEmpty) return;
              onChanged(set.first);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white.withValues(alpha: 0.16);
                }
                return Colors.white.withValues(alpha: 0.06);
              }),
              foregroundColor: WidgetStateProperty.all(
                Colors.white.withValues(alpha: 0.92),
              ),
              side: WidgetStateProperty.all(BorderSide(color: outline)),
            ),
          ),
        ),

        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: onWhite,
                  side: BorderSide(color: outline),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onNext,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                  foregroundColor: onWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(nextLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}