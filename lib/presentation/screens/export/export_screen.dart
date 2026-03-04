import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/export_settings_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../providers/caption_provider.dart';
import '../../providers/export_provider.dart';
import '../../providers/style_provider.dart';
import '../../widgets/common/gradient_background.dart';

/// Export screen with options for video, SRT, and VTT export.
class ExportScreen extends StatefulWidget {
  final String projectId;
  const ExportScreen({super.key, required this.projectId});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ProjectRepository _projectRepo = ProjectRepository();
  ProjectModel? _project;
  ExportSettingsModel _settings = const ExportSettingsModel();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final project = await _projectRepo.getProject(widget.projectId);
    if (mounted) {
      setState(() {
        _project = project;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _project == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Consumer<ExportProvider>(
            builder: (context, exportProv, _) {
              if (exportProv.exportState == ExportState.done) {
                return _buildExportComplete(exportProv);
              }
              if (exportProv.isExporting) {
                return _buildExporting(exportProv);
              }
              return _buildExportOptions();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildExportOptions() {
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

  Widget _buildExporting(ExportProvider exportProv) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            height: 120,
            child: CircularProgressIndicator(
              value: exportProv.exportProgress,
              strokeWidth: 6,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${(exportProv.exportProgress * 100).round()}%',
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.exporting,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportComplete(ExportProvider exportProv) {
    return SizedBox.expand(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: 90,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppStrings.exportComplete,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Auto-saved chip
                  if (exportProv.savedToGallery)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_rounded,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Saved to Gallery',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => exportProv.shareExported(context),
                      icon: const Icon(Icons.share),
                      label: const Text(AppStrings.share),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        exportProv.reset();
                        context.go('/home');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Back to Home',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  void _startExport({required bool includeVideo, bool includeSrt = false}) {
    if (_project == null) return;
    final captions = context.read<CaptionProvider>().captions;
    final style = context.read<StyleProvider>().currentStyle;
    final settings = _settings.copyWith(exportSRT: includeSrt);

    context.read<ExportProvider>().exportVideo(
      videoPath: _project!.videoPath,
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
