// lib/presentation/page/saved_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/repository/saved_heroes_repository.dart';
import '../cubit/saved_heroes/saved_heroes_cubit.dart';
import '../theme/team_colors.dart';
import '../widget/hero_grid_card.dart';

class SavedPage extends StatelessWidget {
  const SavedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SavedHeroesCubit, SavedHeroesState>(
      builder: (context, state) {
        final items = state.savedHeroes;

        return Scaffold(
          appBar: AppBar(title: const Text('Heroes / Villains')),
          body: items.isEmpty
              ? const _EmptyState()
              : LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth;

                    final crossAxisCount = _columnsForWidth(w);

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        mainAxisExtent: 320, // ← styr höjden direkt
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final h = items[index];

                        final team = context.teamColors;
                        final alignNorm = _normalizeAlign(h.alignment);
                        final accent = _alignmentAccent(team, alignNorm);

                        return HeroGridCard(
                          name: h.name,
                          imageUrl: h.imageUrl, // raw url funkar i din setup
                          alignment: alignNorm,
                          accent: accent,
                          attack: h.attack,
                          defense: h.defense,

                          // I Saved-listan är de alltid sparade
                          isSaved: true,
                          onToggleSaved: () =>
                              context.read<SavedHeroesRepository>().removeHero(h.id),

                          onTap: () => context.push('/details/${h.id}'),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

/// normaliserar alignment till 'good'/'bad'/'neutral'
String _normalizeAlign(String raw) {
  final a = raw.toLowerCase().trim();
  if (a.contains('good')) return 'good';
  if (a.contains('bad') || a.contains('evil')) return 'bad';
  return 'neutral';
}

/// accent-färg för outlines + bars (håll den enkel: grön/röd/material)
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_border, size: 44),
            const SizedBox(height: 12),
            Text('No heroes saved yet', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Search and save heroes orvillains, and they will show up here.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

int _columnsForWidth(double w) {
  // Brytpunkter på ett ställe, lätt att tweaka senare.
  if (w < 520) return 2;     // mobil
  if (w < 900) return 3;     // small desktop / stor tablet
  if (w < 1200) return 4;    // desktop
  if (w < 1600) return 5;    // large desktop
  return 6;                  // ultra-wide
}