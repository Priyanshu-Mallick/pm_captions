import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart' as vp;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/file_utils.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../data/datasources/whisper_datasource.dart';
import '../../providers/video_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/error_dialog.dart';
import '../../widgets/common/gradient_background.dart';

/// Screen for selecting a video, choosing language, and entering API key.
class VideoPickerScreen extends StatefulWidget {
  const VideoPickerScreen({super.key});

  @override
  State<VideoPickerScreen> createState() => _VideoPickerScreenState();
}

class _VideoPickerScreenState extends State<VideoPickerScreen> {
  final _apiKeyController = TextEditingController();
  String _selectedLanguage = 'en';
  bool _obscureApiKey = true;
  bool _hasApiKey = false;
  String? _fileSizeStr;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await WhisperDatasource.getApiKey();
    if (key != null && key.isNotEmpty && mounted) {
      setState(() {
        _apiKeyController.text = key;
        _hasApiKey = true;
      });
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final videoProvider = context.watch<VideoProvider>();

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.paddingMD),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      _buildVideoSelector(videoProvider),
                      if (videoProvider.hasVideo) ...[
                        const SizedBox(height: 20),
                        _buildVideoInfo(videoProvider),
                      ],
                      const SizedBox(height: 24),
                      _buildApiKeySection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(AppDimensions.paddingMD),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusLG),
                    topRight: Radius.circular(AppDimensions.radiusLG),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLanguageSelector(),
                    const SizedBox(height: 16),
                    _buildGenerateButton(videoProvider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        Text(
          AppStrings.selectVideo,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoSelector(VideoProvider videoProvider) {
    if (videoProvider.hasVideo && videoProvider.isInitialized) {
      return AspectRatio(
        aspectRatio: videoProvider.videoController?.value.aspectRatio ?? 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                color: Colors.black,
                child:
                    videoProvider.videoController != null
                        ? GestureDetector(
                          onTap: () => videoProvider.togglePlayPause(),
                          child: AspectRatio(
                            aspectRatio:
                                videoProvider
                                    .videoController!
                                    .value
                                    .aspectRatio,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                vp.VideoPlayer(videoProvider.videoController!),
                                if (!videoProvider.isPlaying)
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
                  onTap: () => _pickVideo(videoProvider),
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
      onTap: () => _pickVideo(videoProvider),
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

  Future<void> _pickVideo(VideoProvider videoProvider) async {
    final picked = await videoProvider.pickVideoFromGallery();
    if (picked && videoProvider.selectedVideoPath != null) {
      final sizeMB = await FileUtils.getFileSizeMB(
        videoProvider.selectedVideoPath!,
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
          await videoProvider.reset();
        }
        return;
      }
      // Validate duration
      if (videoProvider.videoDuration.inMinutes >
          AppDimensions.maxVideoDurationMinutes) {
        if (mounted) {
          ErrorDialog.showSnackBar(context, AppStrings.videoTooLong);
          await videoProvider.reset();
        }
      }
    }
  }

  Widget _buildVideoInfo(VideoProvider videoProvider) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
      ),
      child: Row(
        children: [
          _InfoChip(
            icon: Icons.timer_outlined,
            label: AppStrings.duration,
            value: TimeFormatter.durationToDisplay(videoProvider.videoDuration),
          ),
          const SizedBox(width: 16),
          if (_fileSizeStr != null)
            _InfoChip(
              icon: Icons.storage_outlined,
              label: AppStrings.fileSize,
              value: _fileSizeStr!,
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.selectLanguage,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedLanguage,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              style: GoogleFonts.poppins(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
              items:
                  AppStrings.supportedLanguages.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.apiKey,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _apiKeyController,
          obscureText: _obscureApiKey,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: AppStrings.apiKeyHint,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureApiKey
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() => _obscureApiKey = !_obscureApiKey);
              },
            ),
          ),
          onChanged: (value) {
            setState(() => _hasApiKey = value.isNotEmpty);
          },
        ),
      ],
    );
  }

  Widget _buildGenerateButton(VideoProvider videoProvider) {
    final canGenerate =
        videoProvider.hasVideo && _apiKeyController.text.isNotEmpty;

    return CustomButton(
      text: AppStrings.generateCaptions,
      icon: Icons.auto_awesome,
      onPressed: canGenerate ? () => _startProcessing(videoProvider) : null,
    );
  }

  void _startProcessing(VideoProvider videoProvider) {
    final apiKey = _apiKeyController.text.trim();

    if (!WhisperDatasource.isValidKeyFormat(apiKey)) {
      ErrorDialog.showSnackBar(
        context,
        'Invalid key format. Groq keys start with gsk_',
      );
      return;
    }

    context.push(
      '/processing',
      extra: {
        'videoPath': videoProvider.selectedVideoPath!,
        'apiKey': apiKey,
        'language': _selectedLanguage,
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppColors.textHint,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
