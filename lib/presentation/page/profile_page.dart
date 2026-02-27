// lib/presentation/page/profile_page.dart
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/auth/auth_cubit.dart';
import '../cubit/onboarding/onboarding_cubit.dart';
import '../cubit/onboarding/onboarding_state.dart';
import '../cubit/theme/theme_cubit.dart';
import '../cubit/theme/theme_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const _bgDark = 'assets/branding/onboarding_bg.png';
  static const _bgLight = 'assets/branding/onboarding_bg_L.png';

  String _bgAsset(BuildContext context) {
    final b = Theme.of(context).brightness;
    return b == Brightness.dark ? _bgDark : _bgLight;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final fg = scheme.onSurface.withValues(alpha: 0.92);
    final fgSoft = scheme.onSurface.withValues(alpha: isDark ? 0.72 : 0.70);
    final outline = scheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);

    final glassFill = scheme.surface.withValues(alpha: isDark ? 0.10 : 0.38);
    final glassBorder = scheme.outline.withValues(alpha: isDark ? 0.22 : 0.28);

    return BlocBuilder<OnboardingCubit, OnboardingState>(
      builder: (context, state) {
        if (!state.hydrated) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final analyticsEnabled = state.analyticsEnabled;
        final crashlyticsEnabled = state.crashlyticsEnabled;
        final onboardingComplete = state.complete;

        return Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(_bgAsset(context), fit: BoxFit.cover),

              // Vignette (lite starkare i dark, mildare i light)
              Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                      Colors.black.withValues(alpha: isDark ? 0.78 : 0.22),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: _GlassCard(
                        fill: glassFill,
                        border: glassBorder,
                        shadowAlpha: isDark ? 0.35 : 0.18,
                        child: Column(
                          children: [
                            // Header row
                            Row(
                              children: [
                                Text(
                                  'Settings',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        color: fg,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Log out',
                                  onPressed: () => context.read<AuthCubit>().logout(),
                                  icon: Icon(Icons.logout, color: fgSoft),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Divider(height: 1, color: scheme.outline.withValues(alpha: 0.22)),
                            const SizedBox(height: 12),

                            Expanded(
                              child: ListView(
                                padding: EdgeInsets.zero,
                                children: [
                                  // App info
                                  _SectionCard(
                                    outline: outline,
                                    fill: scheme.surface.withValues(alpha: isDark ? 0.06 : 0.55),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'HeroDex 3000',
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                color: fg,
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Onboarding: ${onboardingComplete ? "Complete" : "Not complete"}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fgSoft),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'JXRXN • 🥸 • Version: 0.9.0 • 2026',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fgSoft),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Privacy / consents
                                  _SectionCard(
                                    outline: outline,
                                    fill: scheme.surface.withValues(alpha: isDark ? 0.06 : 0.55),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.privacy_tip_outlined, color: fgSoft),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Privacy',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Control what the app is allowed to collect.',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fgSoft),
                                        ),
                                        const SizedBox(height: 10),

                                        _GlassSwitchTile(
                                          title: 'Analytics',
                                          subtitle: analyticsEnabled ? 'On' : 'Off',
                                          value: analyticsEnabled,
                                          onChanged: (v) => context.read<OnboardingCubit>().setAnalytics(v),
                                          fg: fg,
                                          fgSoft: fgSoft,
                                          outline: outline,
                                        ),
                                        const SizedBox(height: 8),
                                        _GlassSwitchTile(
                                          title: 'Crashlytics',
                                          subtitle: crashlyticsEnabled ? 'On' : 'Off',
                                          value: crashlyticsEnabled,
                                          onChanged: (v) => context.read<OnboardingCubit>().setCrashlytics(v),
                                          fg: fg,
                                          fgSoft: fgSoft,
                                          outline: outline,
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Theme
                                  _SectionCard(
                                    outline: outline,
                                    fill: scheme.surface.withValues(alpha: isDark ? 0.06 : 0.55),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.dark_mode_outlined, color: fgSoft),
                                            const SizedBox(width: 10),
                                            Text(
                                              'Theme',
                                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg),
                                            ),
                                          ],
                                        ),

                                        BlocBuilder<ThemeCubit, ThemeState>(
                                          builder: (context, themeState) {
                                            final mode = themeState.mode;

                                            return Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Center(
                                                  child: SegmentedButton<ThemeMode>(
                                                    // tar bort bock-ikonen
                                                    showSelectedIcon: false,

                                                    // tydlig selected-state (bg + tjockare/primär outline)
                                                    style: ButtonStyle(
                                                      foregroundColor:
                                                          WidgetStateProperty.resolveWith((states) {
                                                        if (states.contains(WidgetState.selected)) {
                                                          return scheme.onSurface;
                                                        }
                                                        return scheme.onSurface.withValues(alpha: 0.78);
                                                      }),
                                                      backgroundColor:
                                                          WidgetStateProperty.resolveWith((states) {
                                                        if (states.contains(WidgetState.selected)) {
                                                          return scheme.primary.withValues(
                                                            alpha: isDark ? 0.22 : 0.14,
                                                          );
                                                        }
                                                        return scheme.surface.withValues(
                                                          alpha: isDark ? 0.10 : 0.55,
                                                        );
                                                      }),
                                                      side: WidgetStateProperty.resolveWith((states) {
                                                        if (states.contains(WidgetState.selected)) {
                                                          return BorderSide(
                                                            color: scheme.primary.withValues(
                                                              alpha: isDark ? 0.75 : 0.55,
                                                            ),
                                                            width: 2,
                                                          );
                                                        }
                                                        return BorderSide(
                                                          color: outline,
                                                          width: 1,
                                                        );
                                                      }),
                                                      overlayColor: WidgetStatePropertyAll(
                                                        scheme.onSurface.withValues(
                                                          alpha: isDark ? 0.08 : 0.06,
                                                        ),
                                                      ),
                                                    ),

                                                    segments: const <ButtonSegment<ThemeMode>>[
                                                      ButtonSegment(
                                                        value: ThemeMode.system,
                                                        label: Text('System', maxLines: 1, softWrap: false),
                                                      ),
                                                      ButtonSegment(
                                                        value: ThemeMode.light,
                                                        label: Text('Light', maxLines: 1, softWrap: false),
                                                      ),
                                                      ButtonSegment(
                                                        value: ThemeMode.dark,
                                                        label: Text('Dark', maxLines: 1, softWrap: false),
                                                      ),
                                                    ],
                                                    selected: <ThemeMode>{mode},
                                                    onSelectionChanged: (set) =>
                                                        context.read<ThemeCubit>().setMode(set.first),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ],
                                    ),
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
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ------------------------------ UI ------------------------------ */

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
    required this.fill,
    required this.border,
    required this.shadowAlpha,
  });

  final Widget child;
  final Color fill;
  final Color border;
  final double shadowAlpha;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: shadowAlpha),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    required this.outline,
    required this.fill,
  });

  final Widget child;
  final Color outline;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outline, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _GlassSwitchTile extends StatelessWidget {
  const _GlassSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.fg,
    required this.fgSoft,
    required this.outline,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color fg;
  final Color fgSoft;
  final Color outline;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: outline, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: fg)),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: fgSoft)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            // activeColor deprecated -> använd thumb/track
            activeThumbColor: scheme.primary,
            inactiveThumbColor: scheme.onSurface.withValues(alpha: 0.60),
            inactiveTrackColor: scheme.surface.withValues(alpha: 0.35),
            activeTrackColor: scheme.primary.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}