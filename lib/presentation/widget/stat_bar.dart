import 'package:flutter/material.dart';

class StatBar extends StatelessWidget {
  const StatBar({
    super.key,
    required this.value,
    this.max = 100,
    required this.fillColor,
    this.height = 10,
    this.radius = 999,
  });

  final int value;
  final int max;
  final Color fillColor;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final clamped = value.clamp(0, max);
    final t = max <= 0 ? 0.0 : (clamped / max).clamp(0.0, 1.0);

    final trackColor = scheme.onSurface.withValues(alpha: 0.10);
    final outlineColor = scheme.onSurface.withValues(alpha: 0.14);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: outlineColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: t,
          child: SizedBox.expand( // ✅ ger fillen full höjd
            child: ColoredBox(color: fillColor),
          ),
        ),
      ),
    );
  }
}