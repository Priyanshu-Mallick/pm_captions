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
import '../../widgets/processing/processing_steps_widget.dart';
import '../../widgets/processing/progress_circle_widget.dart';

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
                    ProgressCircleWidget(provider: provider),
                    const SizedBox(height: 48),
                    // Steps
                    ProcessingStepsWidget(provider: provider),
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
}
