import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/datasources/whisper_datasource.dart';
import '../common/custom_button.dart';
import '../common/error_dialog.dart';

/// Final onboarding step: walks the user through getting and saving their
/// free Groq API key. Reuses [WhisperDatasource] for storage/validation.
///
/// On a successful save it calls [onComplete]; the "Skip for now" action
/// calls [onSkip]. Both ultimately finish onboarding from the parent.
class OnboardingApiKeyStep extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const OnboardingApiKeyStep({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<OnboardingApiKeyStep> createState() => _OnboardingApiKeyStepState();
}

class _OnboardingApiKeyStepState extends State<OnboardingApiKeyStep> {
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _openConsole() async {
    final url = Uri.parse('https://console.groq.com/keys');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _saveAndContinue() async {
    final key = _apiKeyController.text.trim();
    if (!WhisperDatasource.isValidKeyFormat(key)) {
      ErrorDialog.showSnackBar(
        context,
        'Invalid key format. Groq keys start with gsk_',
      );
      return;
    }

    setState(() => _isSaving = true);
    final isValid = await WhisperDatasource.testConnection(key);
    if (!mounted) return;

    if (!isValid) {
      setState(() => _isSaving = false);
      ErrorDialog.showSnackBar(
        context,
        'Connection failed. Please check your key.',
      );
      return;
    }

    await WhisperDatasource.saveApiKey(key);
    if (!mounted) return;
    setState(() => _isSaving = false);
    ErrorDialog.showSuccess(context, 'API key saved');
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.paddingLG),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.key_rounded,
            size: 56,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppDimensions.paddingLG),
          ShaderMask(
            shaderCallback: (bounds) =>
                AppColors.primaryGradient.createShader(bounds),
            child: Text(
              AppStrings.onboardingKeyTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingMD),
          Text(
            AppStrings.onboardingKeySubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          TextField(
            controller: _apiKeyController,
            obscureText: _obscureKey,
            style: GoogleFonts.poppins(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: AppStrings.apiKeyHint,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureKey
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),
          const SizedBox(height: AppDimensions.paddingSM),
          GestureDetector(
            onTap: _openConsole,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.open_in_new,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppDimensions.paddingXS),
                Text(
                  AppStrings.apiKeyLink,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.paddingXL),
          CustomButton(
            text: AppStrings.saveAndContinue,
            icon: Icons.check_rounded,
            isLoading: _isSaving,
            onPressed: _saveAndContinue,
          ),
          const SizedBox(height: AppDimensions.paddingSM),
          TextButton(
            onPressed: _isSaving ? null : widget.onSkip,
            child: Text(
              AppStrings.skipForNow,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
