import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/datasources/whisper_datasource.dart';

/// A dismissible reminder shown on Home when no Groq API key is saved.
///
/// Self-hides when a key exists. Re-checks each time the widget mounts, so it
/// disappears after the user adds a key in Settings and returns. Dismissal is
/// per-session only; it reappears on the next launch while no key is set.
class ApiKeyReminderBanner extends StatefulWidget {
  const ApiKeyReminderBanner({super.key});

  @override
  State<ApiKeyReminderBanner> createState() => _ApiKeyReminderBannerState();
}

class _ApiKeyReminderBannerState extends State<ApiKeyReminderBanner> {
  bool _hasKey = true;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _checkKey();
  }

  Future<void> _checkKey() async {
    final hasKey = await WhisperDatasource.hasApiKey();
    if (mounted) setState(() => _hasKey = hasKey);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasKey || _dismissed) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          onTap: () async {
            await context.push('/settings');
            if (mounted) _checkKey();
          },
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.paddingMD),
            child: Row(
              children: [
                const Icon(
                  Icons.key_rounded,
                  color: AppColors.warning,
                  size: AppDimensions.iconMD,
                ),
                const SizedBox(width: AppDimensions.paddingMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.apiKeyReminderTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.apiKeyReminderSubtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: AppDimensions.iconSM,
                  ),
                  onPressed: () => setState(() => _dismissed = true),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0);
  }
}
