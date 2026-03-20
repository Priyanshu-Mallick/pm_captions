import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart' as vp;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/time_formatter.dart';
import '../../providers/video_provider.dart';
import '../common/error_dialog.dart';
import 'info_chip_widget.dart';

class VideoSelectorWidget extends StatefulWidget {
  final VideoProvider videoProvider;

  const VideoSelectorWidget({super.key, required this.videoProvider});

  @override
  State<VideoSelectorWidget> createState() => _VideoSelectorWidgetState();
}

class _VideoSelectorWidgetState extends State<VideoSelectorWidget> {
  String? _fileSizeStr;

  Future<void> _pickVideo() async {
    final picked = await widget.videoProvider.pickVideoFromGallery();
    if (picked && widget.videoProvider.selectedVideoPath != null) {
      final sizeMB = await FileUtils.getFileSizeMB(
        widget.videoProvider.selectedVideoPath!,
      );
      if (mounted) {
        setState(() {
          _fileSizeStr = '${sizeMB.toStringAsFixed(1)} MB';
        });
      }
      // Validate file size
      if (sizeMB > AppDimensions.maxFileSizeMB) {
        if (mounted) {
          ErrorDialog.showSnackBar(context, AppStrings.fileTooLarge);
          await widget.videoProvider.reset();
        }
        return;
      }
      // Validate duration
      if (widget.videoProvider.videoDuration.inMinutes >
          AppDimensions.maxVideoDurationMinutes) {
        if (mounted) {
          ErrorDialog.showSnackBar(context, AppStrings.videoTooLong);
          await widget.videoProvider.reset();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildVideoSelector(),
        if (widget.videoProvider.hasVideo) ...[
          const SizedBox(height: 20),
          _buildVideoInfo(),
        ],
      ],
    );
  }

  Widget _buildVideoSelector() {
    if (widget.videoProvider.hasVideo && widget.videoProvider.isInitialized) {
      return AspectRatio(
        aspectRatio:
            widget.videoProvider.videoController?.value.aspectRatio ?? 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                color: Colors.black,
                child:
                    widget.videoProvider.videoController != null
                        ? GestureDetector(
                          onTap: () => widget.videoProvider.togglePlayPause(),
                          child: AspectRatio(
                            aspectRatio:
                                widget
                                    .videoProvider
                                    .videoController!
                                    .value
                                    .aspectRatio,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                vp.VideoPlayer(
                                  widget.videoProvider.videoController!,
                                ),
                                if (!widget.videoProvider.isPlaying)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.5,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
              ),
              // Replace video button
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: _pickVideo,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.overlay,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.swap_horiz,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms);
    }

    // Empty state picker
    return GestureDetector(
      onTap: _pickVideo,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_rounded,
              size: 56,
              color: AppColors.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to select a video',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'MP4, MOV, AVI, MKV · Max 500MB',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoInfo() {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Row(
        children: [
          InfoChipWidget(
            icon: Icons.timer_outlined,
            label: AppStrings.duration,
            value: TimeFormatter.durationToDisplay(
              widget.videoProvider.videoDuration,
            ),
          ),
          const SizedBox(width: 16),
          if (_fileSizeStr != null)
            InfoChipWidget(
              icon: Icons.storage_outlined,
              label: AppStrings.fileSize,
              value: _fileSizeStr!,
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
