// lib/presentation/page/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/saved_heroes/saved_heroes_cubit.dart';
import '../theme/team_colors.dart';
import '../widget/pulsing_disabled_button.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  bool _isVillain(String raw) {
    final a = raw.toLowerCase().trim();
    return a.contains('bad') || a.contains('evil');
  }

  bool _isHero(String raw) {
    final a = raw.toLowerCase().trim();
    return a.contains('good');
  }

  @override
  Widget build(BuildContext context) {
    final team = context.teamColors;
    final heroesColor = team.heroes;
    final villainsColor = team.villains;
    final neutralColor = team.neutral;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        toolbarHeight: 0,
      ),
      body: SafeArea(
        top: true,
        child: BlocBuilder<SavedHeroesCubit, SavedHeroesState>(
          builder: (context, state) {
            final items = state.savedHeroes;

            var heroesCount = 0;
            var villainsCount = 0;
            var neutralCount = 0;

            var heroesAttack = 0;
            var heroesDefense = 0;
            var villainsAttack = 0;
            var villainsDefense = 0;
            var neutralAttack = 0;
            var neutralDefense = 0;

            for (final h in items) {
              final align = h.alignment;
              if (_isVillain(align)) {
                villainsCount++;
                villainsAttack += h.attack;
                villainsDefense += h.defense;
              } else if (_isHero(align)) {
                heroesCount++;
                heroesAttack += h.attack;
                heroesDefense += h.defense;
              } else {
                neutralCount++;
                neutralAttack += h.attack;
                neutralDefense += h.defense;
              }
            }

            final totalCount = items.length;

            final totalAtk = heroesAttack + villainsAttack + neutralAttack;
            final totalDef = heroesDefense + villainsDefense + neutralDefense;
            final fightingPower = totalAtk + totalDef;

            final scheme = Theme.of(context).colorScheme;

            return LayoutBuilder(
              builder: (context, c) {
                // Samma beräkning som Attack/Defense-raden: (maxWidth - 16) / 2
                const rowGap = 16.0;
                const horizontalPadding = 18.0; // samma som ListView padding left/right
                final contentWidth = c.maxWidth - (horizontalPadding * 2);
                final oneColWidth = (contentWidth - rowGap) / 2;

                return ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  children: [
                    // ================= POWER (vänster) + ATK/DEF (höger) =================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: oneColWidth,
                          child: _HudStatBox(
                            label: 'POWER',
                            value: fightingPower,
                            border: _hudBorder(context),
                            valueColor: _hudValueColor(context),
                            height: _HudStatBox.defaultHeight,
                          ),
                        ),
                        const SizedBox(width: rowGap),

                        // Höger är flexibel + skalar ned vid trångt läge (ingen overflow)
                        Expanded(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _MiniMetricBox(label: 'ATK', value: totalAtk),
                                  const SizedBox(width: 10),
                                  _MiniMetricBox(label: 'DEF', value: totalDef),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ================= TOTAL (vänster) + rings (höger) =================
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: oneColWidth,
                          child: _HudStatBox(
                            label: 'TOTAL',
                            value: totalCount,
                            border: _hudBorder(context),
                            valueColor: _hudValueColor(context),
                            height: _HudStatBox.defaultHeight,
                          ),
                        ),
                        const SizedBox(width: rowGap),

                        // Samma trick här: flexibel + scaleDown vid behov
                        Expanded(
                          child: Align(
                            alignment: Alignment.topRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.topRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _CountRing(value: heroesCount, color: heroesColor),
                                  const SizedBox(width: 10),
                                  _CountRing(value: villainsCount, color: villainsColor),
                                  const SizedBox(width: 10),
                                  _CountRing(value: neutralCount, color: neutralColor),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    _TeamSection(
                      title: 'Heroes',
                      savedCount: heroesCount,
                      attack: heroesAttack,
                      defense: heroesDefense,
                      color: heroesColor,
                      buttonLabel: 'Deploy Hero',
                    ),
                    const SizedBox(height: 22),

                    _TeamSection(
                      title: 'Villains',
                      savedCount: villainsCount,
                      attack: villainsAttack,
                      defense: villainsDefense,
                      color: villainsColor,
                      buttonLabel: 'Deploy Villain',
                    ),
                    const SizedBox(height: 22),

                    _TeamSection(
                      title: 'Neutral',
                      savedCount: neutralCount,
                      attack: neutralAttack,
                      defense: neutralDefense,
                      color: neutralColor,
                      buttonLabel: 'Deploy Neutral',
                    ),

                    if (items.isEmpty) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Save some heroes or villains in Search to see your total power.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurface.withValues(alpha: 0.65),
                            ),
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  const _TeamSection({
    required this.title,
    required this.savedCount,
    required this.attack,
    required this.defense,
    required this.color,
    required this.buttonLabel,
  });

  final String title;
  final int savedCount;
  final int attack;
  final int defense;
  final Color color;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final border = color.withValues(alpha: 0.70);
    final titleColor = color.withValues(alpha: 0.92);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            _SavedPill(
              text: '$savedCount saved',
              border: border,
              textColor: scheme.onSurface.withValues(alpha: 0.90),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: _StatBox(
                label: 'Attack',
                value: attack,
                color: color,
                border: border,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatBox(
                label: 'Defense',
                value: defense,
                color: color,
                border: border,
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Center(
          child: PulsingDisabledButton(
            label: buttonLabel,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
    required this.border,
  });

  final String label;
  final int value;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final labelStyle = _hudLabelStyle(context).copyWith(
      color: _hudLabelColor(context),
    );

    final valueColor = color.withValues(alpha: 0.92);

    return Container(
      height: _HudStatBox.defaultHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: _hudStroke),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 10,
            child: Text(label, style: labelStyle),
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$value',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudStatBox extends StatelessWidget {
  const _HudStatBox({
    required this.label,
    required this.value,
    required this.border,
    required this.valueColor,
    required this.height,
  });

  static const defaultHeight = 80.0;

  final String label;
  final int value;
  final Color border;
  final Color valueColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final labelStyle = _hudLabelStyle(context).copyWith(
      color: _hudLabelColor(context),
    );

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: _hudStroke),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 10,
            child: Text(label, style: labelStyle),
          ),
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$value',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: valueColor,
                      fontWeight: FontWeight.w600,
                      height: 1.0,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetricBox extends StatelessWidget {
  const _MiniMetricBox({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final labelStyle = _hudLabelStyle(context).copyWith(
      color: _hudLabelColor(context),
      fontSize: 11.5,
    );

    final valueStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: _hudValueColor(context),
          fontWeight: FontWeight.w700,
          height: 1.0,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 4),
          Text('$value', style: valueStyle),
        ],
      ),
    );
  }
}

class _CountRing extends StatelessWidget {
  const _CountRing({
    required this.value,
    required this.color,
  });

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final border = color.withValues(alpha: 0.65);
    final text = color.withValues(alpha: 0.92);

    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: border, width: _hudStroke),
      ),
      child: Text(
        '$value',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: text,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
      ),
    );
  }
}

class _SavedPill extends StatelessWidget {
  const _SavedPill({
    required this.text,
    required this.border,
    required this.textColor,
  });

  final String text;
  final Color border;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border, width: _hudStroke),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

TextStyle _hudLabelStyle(BuildContext context) {
  final base = Theme.of(context).textTheme.labelLarge ?? const TextStyle(fontSize: 12);
  return base.copyWith(
    fontSize: 12,
    letterSpacing: 1.2,
    fontWeight: FontWeight.w600,
  );
}

const double _hudStroke = 1.5;

Color _hudBorder(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return scheme.outlineVariant.withValues(alpha: 0.55);
}

Color _hudLabelColor(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return scheme.onSurfaceVariant.withValues(alpha: 0.85);
}

Color _hudValueColor(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return scheme.onSurface.withValues(alpha: 0.95);
}