import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/repository/saved_heroes_repository.dart';
import '../../data/model/hero_model.dart';
import '../widget/hero_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResistancePage extends StatelessWidget {
  const ResistancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<SavedHeroesRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Heroes / Villains'),
      ),
      body: StreamBuilder<List<SavedHero>>(
        stream: repo.watchSavedHeroes(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final heroes = snap.data ?? const <SavedHero>[];

          if (heroes.isEmpty) {
            return const _EmptyState();
          }

          final total = heroes.length;
          final totalStrength = heroes.fold<int>(0, (sum, h) => sum + h.strength);

          int good = 0, bad = 0, neutral = 0;
          for (final h in heroes) {
            final a = h.alignment.toLowerCase().trim();

            if (a.contains('good')) {
              good++;
            } else if (a.contains('bad') || a.contains('evil')) {
              bad++;
            } else {
              neutral++;
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: heroes.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _Header(
                  total: total,
                  totalStrength: totalStrength,
                  good: good,
                  bad: bad,
                  neutral: neutral,
                );
              }

              final h = heroes[index - 1];

              // Undo behöver en HeroModel för repo.saveHero(...)
              HeroModel asHeroModel(SavedHero s) => HeroModel(
                    id: s.id,
                    name: s.name,
                    imageUrl: s.imageUrl.isEmpty ? null : s.imageUrl,
                    powerstats: {'strength': s.strength},
                    biography: {'alignment': s.alignment},
                    appearance: const {},
                    work: const {},
                  );

              return Dismissible(
                key: ValueKey('saved-${h.id}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.red),
                ),
                confirmDismiss: (_) => _confirmDelete(context, h.name),
                onDismissed: (_) async {
                  await repo.removeHero(h.id);

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text('Tog bort ${h.name}'),
                        action: SnackBarAction(
                          label: 'Ångra',
                          onPressed: () => repo.saveHero(asHeroModel(h)),
                        ),
                        behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: HeroCard(
                    title: h.name,
                    subtitle: 'Strength: ${h.strength} • Alignment: ${_alignmentLabel(h.alignment)}',
                    imageUrl: h.imageUrl,
                    onTap: () => context.push('/details/${h.id}'),
                    trailing: IconButton(
                      tooltip: 'Ta bort från sparade',
                      onPressed: () async {
                        await repo.removeHero(h.id);
                      },
                      icon: const Icon(Icons.bookmark),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _alignmentLabel(String raw) {
    final s = raw.trim();
    return s.isEmpty ? 'unknown' : s;
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ta bort?'),
        content: Text('Ta bort $name från sparade?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Avbryt')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Ta bort')),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.total,
    required this.totalStrength,
    required this.good,
    required this.bad,
    required this.neutral,
  });

  final int total;
  final int totalStrength;
  final int good;
  final int bad;
  final int neutral;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Saved', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              children: [
                _Pill(label: 'Count', value: '$total'),
                _Pill(label: 'Total strength', value: '$totalStrength'),
                _Pill(label: 'Good', value: '$good'),
                _Pill(label: 'Bad', value: '$bad'),
                _Pill(label: 'Neutral', value: '$neutral'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text('$label: $value'),
    );
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
            const Icon(Icons.bookmark_border, size: 44),
            const SizedBox(height: 12),
            Text('Inget sparat än', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Spara några heroes/villains i Search, så dyker de upp här.'),
          ],
        ),
      ),
    );
  }
}