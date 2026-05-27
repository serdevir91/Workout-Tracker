import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/monetization_provider.dart';
import '../services/store_launcher.dart';

class PaywallScreen extends StatelessWidget {
  final String reason;

  const PaywallScreen({super.key, required this.reason});

  Future<void> _openProVersion(BuildContext context) async {
    final opened = await StoreLauncher.openProVersionListing();
    if (!context.mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open the Play Store listing right now.'),
      ),
    );
  }

  Widget _buildFeatureBullet(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Icon(
              Icons.check_circle,
              size: 16,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugCard(BuildContext context, MonetizationProvider monetization) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subscription products are not available yet',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            monetization.lastError ??
                'Google Play returned an empty product catalog for this build.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Text(
            'Expected product IDs: ${monetization.configuredProductIds.join(', ')}',
            style: TextStyle(color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 12),
          Text(
            'Check these items before testing:',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildFeatureBullet(context, 'The free app build was installed from Google Play internal testing.'),
          _buildFeatureBullet(context, 'The subscription products are active in Play Console.'),
          _buildFeatureBullet(context, 'Your tester Gmail is added as a license tester and internal tester.'),
          _buildFeatureBullet(context, 'The device Play Store account is the same account that joined the test.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: monetization.isBusy ? null : monetization.refreshProducts,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh products'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MonetizationProvider>(
      builder: (context, monetization, _) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Go Premium'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Premium Features',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      reason,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _buildFeatureBullet(context, 'Ad-free experience'),
                    _buildFeatureBullet(context, 'Unlimited workout routines'),
                    _buildFeatureBullet(context, 'All-time stats and advanced analytics'),
                    _buildFeatureBullet(context, '1RM analysis on exercise details'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (monetization.isPremiumUnlocked)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Text(
                    monetization.isProBuild
                        ? 'This Pro build already has all premium features unlocked.'
                        : 'Premium is already active on this Google Play account.',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                )
              else if (!monetization.initialized)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (!monetization.canShowBilling)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outline),
                  ),
                  child: Text(
                    'Google Play Billing is not available on this device right now. Install the free app from Google Play internal testing and test with a Play account.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              else if (!monetization.productsLoaded)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (monetization.products.isEmpty)
                _buildDebugCard(context, monetization)
              else
                Column(
                  children: [
                    ...monetization.products.map(
                      (product) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ElevatedButton(
                          onPressed: monetization.isBusy
                              ? null
                              : () => monetization.buy(product),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          child: Text(
                            'Unlock Premium - ${product.price}\n${product.title}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    OutlinedButton(
                      onPressed: monetization.isBusy
                          ? null
                          : () => monetization.restorePurchases(),
                      child: Text(
                        monetization.isBusy
                            ? 'Waiting for Google Play...'
                            : 'Restore Purchases',
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buy Pro Version',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      monetization.isProBuild
                          ? 'You are already using the Pro app. Premium features are unlocked by default.'
                          : 'Prefer a separate Pro app? Buy Workout Tracker Pro from Google Play and keep all premium features unlocked by default.',
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 14),
                    FilledButton(
                      onPressed: monetization.isProBuild
                          ? null
                          : () => _openProVersion(context),
                      child: Text(
                        monetization.isProBuild
                            ? 'Pro Version Active'
                            : 'Open Pro Version on Play Store',
                      ),
                    ),
                  ],
                ),
              ),
              if (monetization.lastError != null && monetization.products.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  monetization.lastError!,
                  style: const TextStyle(color: Color(0xFFFF6B6B)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
