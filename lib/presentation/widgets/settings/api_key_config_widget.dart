import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/datasources/whisper_datasource.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/error_dialog.dart';
import 'settings_section_widget.dart';

class ApiKeyConfigWidget extends StatefulWidget {
  const ApiKeyConfigWidget({super.key});

  @override
  State<ApiKeyConfigWidget> createState() => _ApiKeyConfigWidgetState();
}

class _ApiKeyConfigWidgetState extends State<ApiKeyConfigWidget> {
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await WhisperDatasource.getApiKey();
    if (mounted && key != null) {
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
    return SettingsSectionWidget(
      title: AppStrings.apiKeyConfig,
      icon: Icons.key_rounded,
      children: [
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
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final url = Uri.parse('https://console.groq.com/keys');
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            }
          },
          child: Row(
            children: [
              Icon(Icons.open_in_new, size: 13, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                AppStrings.apiKeyLink,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Save Key',
                height: 40,
                onPressed: () async {
                  await WhisperDatasource.saveApiKey(
                    _apiKeyController.text.trim(),
                  );
                  if (!mounted) return;
                  ErrorDialog.showSuccess(context, 'API key saved');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: AppStrings.testConnection,
                isOutlined: true,
                isLoading: _isTesting,
                height: 40,
                onPressed: () async {
                  setState(() => _isTesting = true);
                  final success = await WhisperDatasource.testConnection(
                    _apiKeyController.text.trim(),
                  );
                  if (!mounted) return;
                  setState(() => _isTesting = false);
                  if (success) {
                    ErrorDialog.showSuccess(context, 'Connection successful!');
                  } else {
                    ErrorDialog.showSnackBar(
                      context,
                      'Connection failed. Check your key.',
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
