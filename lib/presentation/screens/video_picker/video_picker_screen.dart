import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/datasources/whisper_datasource.dart';
import '../../providers/video_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/error_dialog.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/video_picker/api_key_section_widget.dart';
import '../../widgets/video_picker/language_selector_widget.dart';
import '../../widgets/video_picker/video_selector_widget.dart';

/// Screen for selecting a video, choosing language, and entering API key.
class VideoPickerScreen extends StatefulWidget {
  const VideoPickerScreen({super.key});

  @override
  State<VideoPickerScreen> createState() => _VideoPickerScreenState();
}

class _VideoPickerScreenState extends State<VideoPickerScreen> {
  final _apiKeyController = TextEditingController();
  String _selectedLanguage = 'en';

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
                      VideoSelectorWidget(videoProvider: videoProvider),
                      const SizedBox(height: 24),
                      ApiKeySectionWidget(
                        apiKeyController: _apiKeyController,
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
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
                    LanguageSelectorWidget(
                      selectedLanguage: _selectedLanguage,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedLanguage = value);
                        }
                      },
                    ),
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
