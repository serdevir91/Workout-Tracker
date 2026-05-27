import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/monetization_provider.dart';

class EntitlementBadge extends StatelessWidget {
  const EntitlementBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

List<Widget> buildEntitlementBadgeActions(BuildContext context) {
  final monetization = context.watch<MonetizationProvider>();
  final theme = Theme.of(context);

  if (monetization.isSoftOpenMode) {
    return const [];
  }

  if (monetization.isProBuild) {
    return [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Center(
          child: EntitlementBadge(
            label: 'PRO',
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: theme.colorScheme.surface,
          ),
        ),
      ),
    ];
  }

  if (monetization.isPremiumUnlocked) {
    return [
      Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Center(
          child: EntitlementBadge(
            label: 'PREMIUM',
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.16),
            foregroundColor: theme.colorScheme.primary,
          ),
        ),
      ),
    ];
  }

  return const [];
}
