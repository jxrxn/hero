import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';
import 'save_star_button.dart';
import 'stat_bar.dart';

class HeroGridCard extends StatelessWidget {
  const HeroGridCard({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.alignment, // 'good'/'bad'/'neutral'
    required this.accent,
    required this.attack,
    required this.defense,
    required this.isSaved,
    required this.onToggleSaved,
    required this.onTap,
  });

  final String name;
  final String imageUrl;
  final String alignment;
  final Color accent;
  final int attack;
  final int defense;

  final bool isSaved;
  final VoidCallback onToggleSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final borderColor = (alignment == 'good' || alignment == 'bad')
        ? accent
        : scheme.outlineVariant;

    return Semantics(
      container: true,
      label: 'Saved: $name',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: borderColor, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ImageBox(url: imageUrl),
                    const SizedBox(height: 10),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    _StatRow(
                      label: 'Attack',
                      value: attack,
                      max: 100,
                      fillColor: accent,
                    ),
                    const SizedBox(height: 8),
                    _StatRow(
                      label: 'Defense',
                      value: defense,
                      max: 100,
                      fillColor: accent,
                    ),
                  ],
                ),

                // ⭐ top-left
                Positioned(
                  top: -8,
                  left: -8,
                  child: SaveStarButton(
                    isSaved: isSaved,
                    onToggle: onToggleSaved,
                    size: 22,
                    outlineColor: scheme.onSurface.withValues(alpha: 0.30),
                    savedColor: Colors.amber,
                  ),
                ),
              ],
            ),
          ),
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
    final u = url.trim();
    if (u.isEmpty) return const SizedBox(height: 140);

    final resolved = kIsWeb
        ? '${AppConfig.imageProxyBase}?url=${Uri.encodeComponent(u)}'
        : u;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 160),
        child: Image.network(
          resolved,
          fit: BoxFit.contain,
          alignment: Alignment.topCenter,
          errorBuilder: (_, _, _) => const SizedBox(height: 140),
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
    this.max = 100,
  });

  final String label;
  final int value;
  final int max;
  final Color fillColor;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: Theme.of(context).textTheme.bodySmall)),
            Text('$v', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 6),
        StatBar(
          value: v,
          max: max,
          fillColor: fillColor,
        ),
      ],
    );
  }
}