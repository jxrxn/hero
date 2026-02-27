// lib/presentation/widget/hero_card.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.onTap,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Resultat: $title',
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                HeroThumb(url: imageUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing!,
                ],
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Public (inte _Thumb) så du kan återanvända i fler views om du vill.
class HeroThumb extends StatelessWidget {
  const HeroThumb({super.key, required this.url});
  final String? url;

  static String _resolveUrl(String raw) {
    final u = raw.trim();
    if (u.isEmpty) return '';

    // Om den redan är proxad – låt den vara.
    // (Händer om någon annan vy redan har byggt proxy-url.)
    if (kIsWeb && u.startsWith(AppConfig.imageProxyBase)) {
      return u;
    }

    // Proxy bara på webben
    if (kIsWeb) {
      return '${AppConfig.imageProxyBase}?url=${Uri.encodeComponent(u)}';
    }

    return u;
  }

  @override
  Widget build(BuildContext context) {
    final raw = url?.trim() ?? '';
    if (raw.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black12,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.person),
      );
    }

    final resolved = _resolveUrl(raw);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        resolved,
        width: 56,
        height: 56,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 56,
          height: 56,
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image),
        ),
      ),
    );
  }
}