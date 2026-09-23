import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/revenue_cat_service.dart';
import '../../../data/models/caption_style_model.dart';
import '../../../data/models/export_settings_model.dart';
import '../../../data/models/project_model.dart';
import '../../providers/caption_provider.dart';
import '../../providers/export_provider.dart';
import '../../providers/style_provider.dart';
import '../../providers/subscription_provider.dart';
import '../paywall/paywall_bottom_sheet.dart';

class ExportOptionsWidget extends StatefulWidget {
  final ProjectModel project;

  const ExportOptionsWidget({super.key, required this.project});

  @override
  State<ExportOptionsWidget> createState() => _ExportOptionsWidgetState();
}

class _ExportOptionsWidgetState extends State<ExportOptionsWidget> {
  ExportSettingsModel _settings = const ExportSettingsModel();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: AppColors.textPrimary,
                ),
                onPressed: () => context.pop(),
              ),
              Text(
                AppStrings.exportOptions,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildOptionCard(
            icon: Icons.movie_rounded,
            title: AppStrings.videoWithCaptions,
            subtitle: 'MP4 with burned-in subtitles',
            onTap: () => _startExport(includeVideo: true),
          ),
          _buildOptionCard(
            icon: Icons.subtitles_rounded,
            title: AppStrings.srtFile,
            subtitle: 'Standard subtitle file',
            onTap: () => _exportSrt(),
          ),
          _buildOptionCard(
            icon: Icons.closed_caption_rounded,
            title: AppStrings.vttFile,
            subtitle: 'Web video text tracks',
            onTap: () => _exportVtt(),
          ),
          _buildOptionCard(
            icon: Icons.video_library_rounded,
            title: AppStrings.videoAndSrt,
            subtitle: 'Export both video and SRT',
            onTap: () => _startExport(includeVideo: true, includeSrt: true),
          ),
          const SizedBox(height: 24),
          Text(
            AppStrings.quality,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildResolutionSelector(),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildResolutionSelector() {
    return Row(
      children:
          ExportResolution.values.map((res) {
            final isSelected = _settings.resolution == res;
            final label = switch (res) {
              ExportResolution.p720 => '720p',
              ExportResolution.p1080 => '1080p',
              ExportResolution.original => 'Original',
            };
            return Expanded(
              child: GestureDetector(
                onTap:
                    () => setState(() {
                      _settings = _settings.copyWith(resolution: res);
                    }),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }

  /// Single chokepoint for every video export, so the Pro gate lives here and
  /// nowhere else. SRT/VTT-only exports deliberately bypass it: subtitle files
  /// carry no styling, so there is nothing Pro about them.
  Future<void> _startExport({
    required bool includeVideo,
    bool includeSrt = false,
  }) async {
    final style = context.read<StyleProvider>().currentStyle;

    // The style panel only lets you *pick* a Pro template while the feature
    // flag is on, but a project saved earlier (e.g. while testing Pro before
    // the flag existed) can still have one persisted in its style JSON.
    // Checking the flag here — not just relying on the picker — is what
    // makes a disabled build behave as if the feature never existed,
    // regardless of what's sitting in older projects.
    if (RevenueCatService.featureEnabled &&
        style.predefinedTemplate.isPro &&
        !context.read<SubscriptionProvider>().isPro) {
      final unlocked = await PaywallBottomSheet.show(context);
      if (!unlocked || !mounted) return;
    }

    final captions = context.read<CaptionProvider>().captions;
    final settings = _settings.copyWith(exportSRT: includeSrt);

    if (!mounted) return;
    context.read<ExportProvider>().exportVideo(
      videoPath: widget.project.videoPath,
      captions: captions,
      style: style,
      settings: settings,
    );
  }

  void _exportSrt() {
    final captions = context.read<CaptionProvider>().captions;
    context.read<ExportProvider>().exportSRT(captions);
  }

  void _exportVtt() {
    final captions = context.read<CaptionProvider>().captions;
    context.read<ExportProvider>().exportVTT(captions);
  }
}
