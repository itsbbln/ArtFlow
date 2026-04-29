import 'package:flutter/material.dart';

import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/editorial_colors.dart';

class EmptyMessageCard extends StatelessWidget {
  const EmptyMessageCard({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EditorialColors.border.withValues(alpha: 0.82)),
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: EditorialColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
