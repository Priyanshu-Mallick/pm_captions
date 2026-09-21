import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/subscription_provider.dart';

/// Upgrade sheet shown when a free user tries to export a Pro style.
class PaywallBottomSheet extends StatefulWidget {
  const PaywallBottomSheet({super.key});

  /// Shows the paywall. Resolves to whether the user has Pro afterwards, so
  /// the caller can resume whatever the paywall interrupted.
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PaywallBottomSheet(),
    );
    return result ?? false;
  }

  @override
  State<PaywallBottomSheet> createState() => _PaywallBottomSheetState();
}

class _PaywallBottomSheetState extends State<PaywallBottomSheet> {
  Package? _selected;

  static const _features = [
    (Icons.auto_awesome_rounded, '6 viral Pro caption styles'),
    (Icons.lock_open_rounded, 'Export Pro styles without limits'),
    (Icons.video_settings_rounded, 'Full-resolution burned-in captions'),
    (Icons.update_rounded, 'Every future Pro style included'),
  ];

  @override
  void initState() {
    super.initState();
    // Offerings may not have loaded on a cold start with no network.
    final provider = context.read<SubscriptionProvider>();
    if (provider.packages.isEmpty) provider.refreshOfferings();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, sub, _) {
        final packages = sub.packages;
        final selected =
            _selected ?? (packages.isNotEmpty ? packages.first : null);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            gradient: AppColors.cardGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _grabber(),
                  const SizedBox(height: 16),
                  _header(),
                  const SizedBox(height: 20),
                  ..._features.map(_featureRow),
                  const SizedBox(height: 20),
                  if (packages.isEmpty)
                    _unavailableNotice(sub)
                  else
                    ...packages.map(
                      (p) => _packageTile(p, isSelected: p == selected),
                    ),
                  if (sub.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      sub.errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _cta(sub, selected),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: sub.isLoading ? null : () => _restore(sub),
                    child: Text(
                      'Restore Purchases',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  _footer(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _grabber() => Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: AppColors.divider,
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _header() => Column(
    children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFFFD983), Color(0xFFD4AF37)],
          ),
        ),
        child: const Icon(
          Icons.workspace_premium_rounded,
          size: 30,
          color: Color(0xFF3A2B00),
        ),
      ),
      const SizedBox(height: 14),
      Text(
        'Unlock PM Captions Pro',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'Export the viral caption styles built for TikTok, Reels and Shorts.',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
      ),
    ],
  );

  Widget _featureRow((IconData, String) feature) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(feature.$1, size: 18, color: AppColors.success),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            feature.$2,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _packageTile(Package package, {required bool isSelected}) {
    final isAnnual = package.packageType == PackageType.annual;
    final product = package.storeProduct;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => setState(() => _selected = package),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                size: 20,
                color:
                    isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title.isNotEmpty
                          ? product.title
                          : (isAnnual ? 'Annual' : 'Monthly'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      product.priceString,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAnnual)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'BEST VALUE',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shown when RevenueCat has no keys or the offerings could not load, so the
  /// sheet still explains itself instead of appearing broken.
  Widget _unavailableNotice(SubscriptionProvider sub) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.divider),
    ),
    child: Text(
      sub.isStoreAvailable
          ? 'Pricing could not be loaded. Check your connection and try again.'
          : 'Subscriptions are not available on this build yet.',
      textAlign: TextAlign.center,
      style: GoogleFonts.poppins(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
    ),
  );

  Widget _cta(SubscriptionProvider sub, Package? selected) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed:
          (sub.isLoading || selected == null)
              ? null
              : () => _purchase(sub, selected),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        disabledBackgroundColor: AppColors.divider,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child:
          sub.isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : Text(
                'Unlock Pro',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
    ),
  );

  Widget _footer() => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Column(
      children: [
        Text(
          'Subscriptions renew automatically until cancelled. Manage or cancel '
          'any time in your store account settings.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: AppColors.textHint,
          ),
        ),
        TextButton(
          onPressed: () async {
            final url = Uri.parse(AppStrings.privacyPolicyUrl);
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
          child: Text(
            'Privacy Policy & Terms',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    ),
  );

  Future<void> _purchase(SubscriptionProvider sub, Package package) async {
    final isPro = await sub.purchase(package);
    if (isPro && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _restore(SubscriptionProvider sub) async {
    final isPro = await sub.restore();
    if (isPro && mounted) Navigator.of(context).pop(true);
  }
}
