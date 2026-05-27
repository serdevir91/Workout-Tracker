import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import '../providers/monetization_provider.dart';
import '../services/ad_service.dart';

class BannerAdSlot extends StatefulWidget {
  final AdPlacement placement;

  const BannerAdSlot({super.key, required this.placement});

  @override
  State<BannerAdSlot> createState() => _BannerAdSlotState();
}

class _BannerAdSlotState extends State<BannerAdSlot> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final monetization = context.read<MonetizationProvider>();
    if (!monetization.adsEnabled || !AdService.instance.isSupportedPlatform) {
      return;
    }

    try {
      final banner = await AdService.instance.createBanner(widget.placement);
      if (!mounted) {
        banner.dispose();
        return;
      }
      setState(() {
        _banner = banner;
        _loaded = true;
      });
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant BannerAdSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement != widget.placement) {
      _banner?.dispose();
      _banner = null;
      _loaded = false;
      _loadAd();
    }
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MonetizationProvider>(
      builder: (context, monetization, _) {
        if (!monetization.adsEnabled || !_loaded || _banner == null) {
          return const SizedBox.shrink();
        }
        return Container(
          width: _banner!.size.width.toDouble(),
          height: _banner!.size.height.toDouble(),
          alignment: Alignment.center,
          color: Theme.of(context).scaffoldBackgroundColor,
          child: AdWidget(ad: _banner!),
        );
      },
    );
  }
}
