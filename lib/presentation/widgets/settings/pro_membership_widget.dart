import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../providers/subscription_provider.dart';
import '../paywall/paywall_bottom_sheet.dart';
import 'settings_section_widget.dart';

/// Settings entry point for the Pro subscription.
class ProMembershipWidget extends StatelessWidget {
  const ProMembershipWidget({super.key});

  static const _gold = Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, sub, _) {
        return SettingsSectionWidget(
          title: 'PM Captions Pro',
          icon: Icons.workspace_premium_rounded,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: sub.isPro ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _gold.withValues(alpha: 0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.isPro ? 'Pro member' : 'Upgrade to Pro',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sub.isPro
                        ? 'All Pro caption styles are unlocked for export.'
                        : 'Unlock 6 viral caption styles and export them '
                            'without restrictions.',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (sub.isPro)
                    _button(
                      label: 'Restore Purchases',
                      filled: false,
                      onPressed: sub.isLoading ? null : () => sub.restore(),
                    )
                  else
                    _button(
                      label: 'Upgrade',
                      filled: true,
                      onPressed: () => PaywallBottomSheet.show(context),
                    ),
                  if (kDebugMode) ...[
                    const Divider(color: AppColors.divider, height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Simulate Pro (debug only)',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        Switch(
                          value: sub.isDebugPro,
                          onChanged: (_) => sub.toggleDebugPro(),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _button({
    required String label,
    required bool filled,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? _gold : Colors.transparent,
          elevation: filled ? 1 : 0,
          side: filled ? null : const BorderSide(color: _gold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: filled ? const Color(0xFF3A2B00) : _gold,
          ),
        ),
      ),
    );
  }
}
