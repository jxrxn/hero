import 'package:flutter/material.dart';

class SaveStarButton extends StatefulWidget {
  const SaveStarButton({
    super.key,
    required this.isSaved,
    required this.onToggle,
    this.size = 22,
    this.savedColor,
    this.outlineColor,
    this.tooltip,
  });

  final bool isSaved;
  final VoidCallback onToggle;

  /// Ikonstorlek
  final double size;

  /// Färg när sparad (default: amber)
  final Color? savedColor;

  /// Konturfärg när inte sparad (default: onSurface 35%)
  final Color? outlineColor;

  final String? tooltip;

  @override
  State<SaveStarButton> createState() => _SaveStarButtonState();
}

class _SaveStarButtonState extends State<SaveStarButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 140),
    );

    _scale = Tween<double>(begin: 1.0, end: 1.30).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant SaveStarButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Om den blir "unsaved" utifrån (t.ex. stream uppdateras), se till att skalan återställs.
    if (!widget.isSaved && _controller.value != 0) {
      _controller.value = 0;
    }
  }

  Future<void> _handleTap() async {
    final wasSaved = widget.isSaved;

    // För “lägg till”: poppa lite
    if (!wasSaved) {
      await _controller.forward();
      if (!mounted) return;
      await _controller.reverse();
      if (!mounted) return;
    }

    widget.onToggle();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final savedFill = widget.savedColor ?? Colors.amber;
    final outline = widget.outlineColor ??
        scheme.onSurface.withValues(alpha: 0.35); // samma “känsla” som track

    final icon = widget.isSaved ? Icons.star : Icons.star_border;
    final color = widget.isSaved ? savedFill : Colors.transparent;

    // Vi ritar outline även när den är fylld, så den matchar “track”-konturen.
    final border = widget.isSaved
        ? savedFill.withValues(alpha: 0.75)
        : outline;

    final tt = widget.tooltip ?? (widget.isSaved ? 'Ta bort' : 'Spara');

    return Semantics(
      button: true,
      label: tt,
      child: Tooltip(
        message: tt,
        child: ScaleTransition(
          scale: _scale,
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _handleTap,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outline-lager
                    Icon(
                      Icons.star_border,
                      size: widget.size + 1,
                      color: border,
                    ),
                    // Fill-lager (transparent när inte sparad)
                    Icon(
                      icon,
                      size: widget.size,
                      color: widget.isSaved ? savedFill : outline,
                    ),
                    if (!widget.isSaved)
                      Icon(
                        Icons.star,
                        size: widget.size,
                        color: color, // transparent
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}