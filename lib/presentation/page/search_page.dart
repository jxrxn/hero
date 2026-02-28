import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/alignment_utils.dart';
import '../cubit/search/search_cubit.dart';
import '../cubit/search/search_state.dart';
import '../widget/save_star_button.dart';
import '../theme/team_colors.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  static const _bgDark = 'assets/branding/onboarding_bg.png';
  static const _bgLight = 'assets/branding/onboarding_bg_L.png';

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _bgAsset(BuildContext context) {
    final b = Theme.of(context).brightness;
    return b == Brightness.dark ? SearchPage._bgDark : SearchPage._bgLight;
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SearchCubit>();
    final scheme = Theme.of(context).colorScheme;
    final team = context.teamColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware “glass tokens”
    final fg = scheme.onSurface.withValues(alpha: isDark ? 0.92 : 0.92);
    final fgSoft = scheme.onSurface.withValues(alpha: isDark ? 0.72 : 0.70);
    final outline = scheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);

    final glassFill = scheme.surface.withValues(alpha: isDark ? 0.10 : 0.28);
    final glassBorder = scheme.outline.withValues(alpha: isDark ? 0.22 : 0.28);

    void clearAll() {
      _controller.clear();
      cubit.clear();
      FocusScope.of(context).unfocus();
    }

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
                        // Search field (med ✕-kryss)
                        BlocBuilder<SearchCubit, SearchState>(
                          buildWhen: (p, n) => p.query != n.query,
                          builder: (context, state) {
                            // Håll TextField synkad när vi rensar via cubit.clear()
                            if (state.query != _controller.text) {
                              _controller.value = TextEditingValue(
                                text: state.query,
                                selection: TextSelection.collapsed(
                                  offset: state.query.length,
                                ),
                              );
                            }

                            return TextField(
                              controller: _controller,
                              decoration: _inputDecoration(
                                context: context,
                                label: 'Search hero / villain',
                                hint: 'e.g. batman',
                                outline: outline,
                                fg: fg,
                                fgSoft: fgSoft,
                                scheme: scheme,
                                isDark: isDark,
                                showClear: state.query.trim().isNotEmpty,
                                onClear: clearAll,
                              ),
                              style: TextStyle(color: fg),
                              textInputAction: TextInputAction.search,
                              onChanged: cubit.onQueryChanged,
                            );
                          },
                        ),

                        const SizedBox(height: 12),
                        Divider(height: 1, color: scheme.outline.withValues(alpha: 0.22)),
                        const SizedBox(height: 10),

                        // Results / empty states (scroll-safe in landscape)
                        Expanded(
                          child: BlocBuilder<SearchCubit, SearchState>(
                            builder: (context, state) {
                              if (state.status == SearchStatus.loading) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: scheme.primary,
                                  ),
                                );
                              }

                              if (state.status == SearchStatus.failure) {
                                return _ScrollableEmpty(
                                  child: _EmptyState(
                                    icon: Icons.wifi_off,
                                    title: 'Search failed',
                                    subtitle: state.errorMessage ?? 'Unknown error.',
                                    onClear: clearAll,
                                    fg: fg,
                                    fgSoft: fgSoft,
                                    outline: outline,
                                  ),
                                );
                              }

                              if (state.query.trim().isEmpty) {
                                return _ScrollableEmpty(
                                  topPadding: 8,
                                  child: _EmptyState(
                                    icon: Icons.search,
                                    title: 'Search the database',
                                    subtitle: 'Type a name to search in SuperheroAPI.',
                                    onClear: null,
                                    fg: fg,
                                    fgSoft: fgSoft,
                                    outline: outline,
                                  ),
                                );
                              }

                              if (state.results.isEmpty) {
                                return _ScrollableEmpty(
                                  child: _EmptyState(
                                    icon: Icons.sentiment_dissatisfied,
                                    title: 'No results',
                                    subtitle: state.errorMessage ?? 'Try another name.',
                                    onClear: clearAll,
                                    fg: fg,
                                    fgSoft: fgSoft,
                                    outline: outline,
                                  ),
                                );
                              }

                              return ListView.separated(
                                padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                                itemCount: state.results.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final hero = state.results[i];
                                  final img = hero.imageUrl;
                                  final subtitle = _subtitleFor(hero);

                                  final isSaved = state.isSaved(hero.id);
                                  final isSaving = state.isSaving(hero.id);

                                  final bioAlign = (hero.biography['alignment'] as String?)?.trim();

                                  // HeroModel.alignment är redan icke-null String.
                                  // Vi tar biography['alignment'] om det finns och inte är tomt,
                                  // annars använder vi hero.alignment (som i sin tur redan faller tillbaka till '').
                                  final rawAlign = (bioAlign == null || bioAlign.isEmpty) ? hero.alignment : bioAlign;

                                  final alignNorm = normalizeAlign(rawAlign);
                                  final accent = _alignmentAccent(team, alignNorm);

                                  final borderColor = (alignNorm == 'good' || alignNorm == 'bad')
                                      ? accent.withValues(alpha: 0.70)
                                      : scheme.outline.withValues(alpha: 0.35);

                                  return Semantics(
                                    container: true,
                                    label: 'Result: ${hero.name}. ${isSaved ? "Saved." : "Not saved."}',
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(16),
                                      onTap: () => context.push('/details/${hero.id}'),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: borderColor, width: 1),
                                          color: scheme.surface.withValues(alpha: isDark ? 0.06 : 0.55),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              _Thumb(url: img),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      hero.name,
                                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                            color: fg,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      subtitle,
                                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                            color: fgSoft,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Semantics(
                                                button: true,
                                                label: isSaved
                                                    ? 'Remove ${hero.name} from saved'
                                                    : 'Save ${hero.name}',
                                                child: isSaving
                                                    ? SizedBox(
                                                        width: 22,
                                                        height: 22,
                                                        child: CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: scheme.primary,
                                                        ),
                                                      )
                                                    : SaveStarButton(
                                                        isSaved: isSaved,
                                                        onToggle: () => context.read<SearchCubit>().toggleSave(hero),
                                                        outlineColor: scheme.onSurface.withValues(alpha: 0.28),
                                                        savedColor: Colors.amber,
                                                        size: 22,
                                                      ),
                                              ),
                                              const SizedBox(width: 6),
                                              Icon(Icons.chevron_right, color: fgSoft),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
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
  }

  InputDecoration _inputDecoration({
    required BuildContext context,
    required String label,
    required String hint,
    required Color outline,
    required Color fg,
    required Color fgSoft,
    required ColorScheme scheme,
    required bool isDark,
    required bool showClear,
    required VoidCallback onClear,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: fgSoft),
      hintStyle: TextStyle(color: fgSoft.withValues(alpha: 0.75)),
      prefixIcon: Icon(Icons.search, color: fgSoft),
      suffixIcon: showClear
          ? IconButton(
              tooltip: 'Clear search',
              icon: Icon(Icons.close, color: fgSoft),
              onPressed: onClear,
            )
          : null,
      filled: true,
      fillColor: scheme.surface.withValues(alpha: isDark ? 0.06 : 0.55),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.primary.withValues(alpha: 0.55)),
      ),
    );
  }

  String _subtitleFor(dynamic hero) {
    try {
      final strength = hero.powerstats?.strength ?? hero.strength ?? 0;
      final bioAlign = (hero.biography['alignment'] as String?)?.trim();
      final rawAlign = (bioAlign == null || bioAlign.isEmpty) ? hero.alignment : bioAlign;
      final a = normalizeAlign(rawAlign);
      return 'Strength: $strength • Alignment: $a';
    } catch (_) {
      return 'Tap for details';
    }
  }
}

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

class _ScrollableEmpty extends StatelessWidget {
  const _ScrollableEmpty({required this.child, this.topPadding = 0});
  final Widget child;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        return SingleChildScrollView(
          padding: EdgeInsets.only(top: topPadding),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: c.maxHeight - topPadding),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onClear,
    required this.fg,
    required this.fgSoft,
    required this.outline,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onClear;
  final Color fg;
  final Color fgSoft;
  final Color outline;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: fgSoft),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: fg),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fgSoft),
          ),
          if (onClear != null) ...[
            const SizedBox(height: 14),
            OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: outline),
              ),
              child: const Text('Clear'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    final u = url?.trim();

    if (u == null || u.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
        ),
        child: const Icon(Icons.person),
      );
    }

    final imageUrl =
        kIsWeb ? '${AppConfig.imageProxyBase}?url=${Uri.encodeComponent(u)}' : u;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 56,
          height: 56,
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image),
        ),
      ),
    );
  }
}

Color _alignmentAccent(TeamColors team, String alignment) {
  switch (alignment) {
    case 'good':
      return team.heroes;
    case 'bad':
      return team.villains;
    default:
      return team.neutral;
  }
}