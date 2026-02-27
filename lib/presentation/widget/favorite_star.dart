import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/model/hero_model.dart';
import '../../data/repository/saved_heroes_repository.dart';

class FavoriteStar extends StatelessWidget {
  const FavoriteStar({
    super.key,
    required this.hero,
  });

  final HeroModel hero;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final repo = context.read<SavedHeroesRepository>();

    return StreamBuilder<bool>(
      stream: repo.isSavedStream(hero.id),
      builder: (context, snap) {
        final isSaved = snap.data ?? false;

        final outlineColor = scheme.onSurface.withValues(alpha: 0.30);

        return IconButton(
          tooltip: isSaved ? 'Ta bort från samling' : 'Lägg till i samling',
          onPressed: () async {
            if (isSaved) {
              await repo.removeHero(hero.id);
            } else {
              await repo.saveHero(hero);
            }
          },
          icon: Icon(
            isSaved ? Icons.star : Icons.star_border,
            color: isSaved ? Colors.amber : outlineColor,
          ),
        );
      },
    );
  }
}