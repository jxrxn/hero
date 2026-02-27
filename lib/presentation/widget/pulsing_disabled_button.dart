import 'package:flutter/material.dart';

class PulsingDisabledButton extends StatefulWidget {
  const PulsingDisabledButton({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  State<PulsingDisabledButton> createState() =>
      _PulsingDisabledButtonState();
}

class _PulsingDisabledButtonState
    extends State<PulsingDisabledButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return IgnorePointer(
      ignoring: true, // 🔒 alltid disabled
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, _) {
          final scale = 0.98 + (0.04 * _curve.value);
          final glowAlpha = 0.08 + (0.14 * _curve.value);

          return Transform.scale(
            scale: scale,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: glowAlpha),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 18,
                  ),
                  side: BorderSide(
                    color: widget.color.withValues(alpha: 0.7),
                    width: 2.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                child: Text(
                  widget.label,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color: scheme.onSurface
                            .withValues(alpha: 0.55),
                      ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}