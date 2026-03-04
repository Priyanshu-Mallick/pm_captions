import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../providers/processing_provider.dart';
import '../../providers/video_provider.dart';
import '../../widgets/common/gradient_background.dart';

/// Screen that shows processing progress through the pipeline.
class ProcessingScreen extends StatefulWidget {
  final String videoPath;
  final String apiKey;
  final String language;

  const ProcessingScreen({
    super.key,
    required this.videoPath,
    required this.apiKey,
    required this.language,
  });

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startProcessing();
    });
  }

  Future<void> _startProcessing() async {
    final provider = context.read<ProcessingProvider>();
    await provider.startProcessing(
      videoPath: widget.videoPath,
      apiKey: widget.apiKey,
      language: widget.language,
    );

    // On success, create project and navigate to editor
    if (provider.currentState == ProcessingState.done && mounted) {
      final vp = context.read<VideoProvider>();
      await vp.initializeVideo(widget.videoPath);
      final thumbPath = await vp.generateThumbnail(widget.videoPath);

      final project = ProjectModel.create(
        name: widget.videoPath.split('/').last.split('.').first,
        videoPath: widget.videoPath,
        thumbnailPath: thumbPath ?? '',
        videoDuration: vp.videoDuration,
      );

      final projectRepo = ProjectRepository();
      await projectRepo.saveProject(project, provider.captions);

      if (mounted) {
        context.go('/editor/${project.id}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Consumer<ProcessingProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.all(AppDimensions.paddingLG),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Progress circle
                    _buildProgressCircle(provider),
                    const SizedBox(height: 48),
                    // Steps
                    _buildSteps(provider),
                    const SizedBox(height: 48),
                    // Status message
                    Text(
                      provider.statusMessage,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ).animate().fadeIn(),
                    const SizedBox(height: 32),
                    // Error or Cancel button
                    if (provider.currentState == ProcessingState.error) ...[
                      Text(
                        provider.errorMessage ?? AppStrings.genericError,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              provider.reset();
                              context.pop();
                            },
                            child: const Text('Go Back'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () {
                              provider.reset();
                              _startProcessing();
                            },
                            child: const Text(AppStrings.retry),
                          ),
                        ],
                      ),
                    ] else if (provider.isProcessing)
                      TextButton.icon(
                        onPressed: () {
                          provider.cancel();
                          context.pop();
                        },
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                        ),
                        label: Text(
                          AppStrings.cancel,
                          style: GoogleFonts.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCircle(ProcessingProvider provider) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: provider.progress,
              strokeWidth: 6,
              backgroundColor: AppColors.divider,
              valueColor: AlwaysStoppedAnimation<Color>(
                provider.currentState == ProcessingState.error
                    ? AppColors.error
                    : AppColors.primary,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(provider.progress * 100).round()}%',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                AppStrings.processing,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1, 1),
      duration: 600.ms,
      curve: Curves.elasticOut,
    );
  }

  Widget _buildSteps(ProcessingProvider provider) {
    return Column(
      children: [
        _StepItem(
          label: AppStrings.extractingAudio,
          isActive: provider.currentState == ProcessingState.extractingAudio,
          isDone:
              provider.currentState.index >
              ProcessingState.extractingAudio.index,
        ),
        const SizedBox(height: 12),
        _StepItem(
          label: AppStrings.transcribingSpeech,
          isActive: provider.currentState == ProcessingState.transcribing,
          isDone:
              provider.currentState.index > ProcessingState.transcribing.index,
        ),
        const SizedBox(height: 12),
        _StepItem(
          label: AppStrings.generatingCaptions,
          isActive: provider.currentState == ProcessingState.groupingCaptions,
          isDone:
              provider.currentState.index >
              ProcessingState.groupingCaptions.index,
        ),
        const SizedBox(height: 12),
        _StepItem(
          label: AppStrings.finalizing,
          isActive: provider.currentState == ProcessingState.done,
          isDone: provider.currentState == ProcessingState.done,
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }
}

class _StepItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepItem({
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isDone
                    ? AppColors.success
                    : isActive
                    ? AppColors.primary
                    : AppColors.surface,
            border: Border.all(
              color:
                  isDone
                      ? AppColors.success
                      : isActive
                      ? AppColors.primary
                      : AppColors.divider,
            ),
          ),
          child:
              isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : isActive
                  ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color:
                  isDone || isActive
                      ? AppColors.textPrimary
                      : AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}
