// lib/presentation/page/details_page.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/config/app_config.dart';
import '../../data/model/hero_model.dart';
import '../../data/remote/superhero_api_client.dart';
import '../../data/repository/saved_heroes_repository.dart';
import '../widget/save_star_button.dart';
import '../theme/team_colors.dart';
import '../widget/stat_bar.dart';

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final api = context.read<SuperheroApiClient>();

    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: FutureBuilder<HeroModel?>(
        future: api.getById(id),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.hasError) {
            return _ErrorState(
              title: 'Kunde inte ladda',
              subtitle: 'Något gick fel när vi hämtade hjälten.',
              onRetry: () => (context as Element).markNeedsBuild(),
            );
          }

          final hero = snap.data;
          if (hero == null || hero.id.trim().isEmpty) {
            return _ErrorState(
              title: 'Ingen data',
              subtitle: 'Kunde inte hitta hero med id: $id',
              onRetry: () => (context as Element).markNeedsBuild(),
            );
          }

          final team = context.teamColors;

          // alignment: 'good'/'bad'/'neutral'
          final alignNorm = hero.alignmentNormalized;
          final accent = alignmentAccent(alignNorm, team);

          final imageUrl = _resolveImageUrl(hero.imageUrl);

          int stat(String key) => _safeStat(hero.powerstats[key], max: 100);
          final strength = stat('strength');
          final speed = stat('speed');
          final power = stat('power');
          final combat = stat('combat');
          final intelligence = stat('intelligence');
          final durability = stat('durability');

          final rating = _calcCombat(
            strength: strength,
            speed: speed,
            power: power,
            combat: combat,
            intelligence: intelligence,
            durability: durability,
          );

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _HeaderCard(
                    hero: hero, // ✅ NYTT
                    imageUrl: imageUrl,
                    alignment: alignNorm,
                    accent: accent,
                    attack: rating.attack,
                    defense: rating.defense,
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Powerstats',
                    alignment: alignNorm,
                    accent: accent,
                    children: [
                      _StatRow(label: 'Strength', value: strength, fillColor: accent),
                      const SizedBox(height: 10),
                      _StatRow(label: 'Speed', value: speed, fillColor: accent),
                      const SizedBox(height: 10),
                      _StatRow(label: 'Power', value: power, fillColor: accent),
                      const SizedBox(height: 10),
                      _StatRow(label: 'Combat', value: combat, fillColor: accent),
                      const SizedBox(height: 10),
                      _StatRow(label: 'Intelligence', value: intelligence, fillColor: accent),
                      const SizedBox(height: 10),
                      _StatRow(label: 'Durability', value: durability, fillColor: accent),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Biography',
                    alignment: alignNorm,
                    accent: accent,
                    children: [
                      _RowKV('Full name', hero.fullName),
                      _RowKV('Alignment', hero.alignment.isEmpty ? 'unknown' : hero.alignment),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Color alignmentAccent(String alignment, TeamColors team) {
  switch (alignment) {
    case 'good':
      return team.heroes;
    case 'bad':
      return team.villains;
    default:
      return team.neutral;
  }
}

/* ------------------------------ helpers ------------------------------ */

String _resolveImageUrl(String? raw) {
  final u = raw?.trim();
  if (u == null || u.isEmpty) return '';
  if (!kIsWeb) return u;
  return '${AppConfig.imageProxyBase}?url=${Uri.encodeComponent(u)}';
}

int _safeStat(dynamic v, {int max = 100}) {
  if (v == null) return 0;
  final s = v.toString().trim().toLowerCase();
  if (s.isEmpty || s == 'null' || s == '-' || s == 'unknown') return 0;
  final n = int.tryParse(s) ?? 0;
  if (n < 0) return 0;
  if (n > max) return max;
  return n;
}

_Combat _calcCombat({
  required int strength,
  required int speed,
  required int power,
  required int combat,
  required int intelligence,
  required int durability,
}) {
  final atk = (strength * 0.35) + (power * 0.35) + (combat * 0.20) + (speed * 0.10);
  final def = (durability * 0.50) + (speed * 0.20) + (intelligence * 0.20) + (combat * 0.10);

  int clamp100(num x) {
    final r = x.round();
    if (r < 0) return 0;
    if (r > 100) return 100;
    return r;
  }

  return _Combat(attack: clamp100(atk), defense: clamp100(def));
}

class _Combat {
  const _Combat({required this.attack, required this.defense});
  final int attack;
  final int defense;
}

/* ------------------------------ UI widgets ------------------------------ */

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.hero,
    required this.imageUrl,
    required this.alignment,
    required this.accent,
    required this.attack,
    required this.defense,
  });

  final HeroModel hero;
  final String imageUrl;
  final String alignment;
  final Color accent;
  final int attack;
  final int defense;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final repo = context.read<SavedHeroesRepository>();

    final borderColor =
        (alignment == 'good' || alignment == 'bad')
            ? accent
            : scheme.outlineVariant.withValues(alpha: 0.55);

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ImageBox(url: imageUrl),
                const SizedBox(height: 12),
                Text(
                  hero.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                _StatRow(
                  label: 'Attack',
                  value: attack,
                  fillColor: accent,
                ),
                const SizedBox(height: 10),
                _StatRow(
                  label: 'Defense',
                  value: defense,
                  fillColor: accent,
                ),
              ],
            ),

            // ⭐ Star (top-left)
            Positioned(
              top: 0,
              left: 0,
              child: StreamBuilder<bool>(
                stream: repo.isSavedStream(hero.id),
                initialData: false,
                builder: (context, snap) {
                  final isSaved = snap.data ?? false;

                  return SaveStarButton(
                    isSaved: isSaved,
                    onToggle: () => repo.toggleHero(hero),
                    // valfritt:
                    // size: 22,
                    // outlineColor: scheme.onSurface.withValues(alpha: 0.30),
                    // savedColor: Colors.amber,
                  );
                },
              ),
            ),

            // Alignment badge (top-right)
            Positioned(
              top: 0,
              right: 0,
              child: _AlignmentBadge(
                alignment: alignment,
                accent: accent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageBox extends StatelessWidget {
  const _ImageBox({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final u = url.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 240, // behåll din “bra” höjd-känsla, men utan crop
        ),
        child: u.isEmpty
            ? SizedBox(
                height: 240,
                child: Center(
                  child: Icon(Icons.person, size: 52, color: scheme.onSurfaceVariant),
                ),
              )
            : Image.network(
                u,
                fit: BoxFit.contain, // ✅ visar hela bilden
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) => SizedBox(
                  height: 240,
                  child: Center(
                    child: Icon(Icons.broken_image, size: 40, color: scheme.onSurfaceVariant),
                  ),
                ),
              ),
      ),
    );
  }
}

class _AlignmentBadge extends StatelessWidget {
  const _AlignmentBadge({required this.alignment, required this.accent});
  final String alignment;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = alignment.toUpperCase();

    // ✅ ersätter withOpacity
    final bg = accent.withValues(alpha: 0.14);
    final fg = (alignment == 'bad') ? scheme.error : accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg, width: 1),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.children,
    required this.alignment,
    required this.accent,
  });

  final String title;
  final List<Widget> children;
  final String alignment;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = (alignment == 'good' || alignment == 'bad')
        ? accent
        : scheme.outlineVariant;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.fillColor,
  });

  final String label;
  final int value;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    const int max = 100;

    final int v = value < 0 ? 0 : (value > max ? max : value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            Text('$v',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 6),
        StatBar(
          value: v,
          max: 100,
          fillColor: fillColor,
        ),
      ],
    );
  }
}

class _RowKV extends StatelessWidget {
  const _RowKV(this.keyLabel, this.value);
  final String keyLabel;
  final String value;

  @override
  Widget build(BuildContext context) {
    final v = value.trim();
    if (v.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(keyLabel, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(v, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final String title;
  final String subtitle;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Försök igen'),
            ),
          ],
        ),
      ),
    );
  }
}