import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/datasources/whisper_datasource.dart';
import '../../../data/repositories/project_repository.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/error_dialog.dart';
import '../../widgets/common/gradient_background.dart';

/// Settings screen for API key, default language, and app management.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  String _defaultLanguage = 'en';
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final key = await WhisperDatasource.getApiKey();
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('default_language') ?? 'en';
    if (mounted) {
      setState(() {
        if (key != null) _apiKeyController.text = key;
        _defaultLanguage = lang;
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
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.paddingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildApiKeySection(),
                const SizedBox(height: 24),
                _buildDefaultLanguage(),
                const SizedBox(height: 24),
                _buildDangerZone(),
                const SizedBox(height: 32),
                _buildAbout(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        Text(
          AppStrings.settings,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildApiKeySection() {
    return _SettingsSection(
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
        Row(
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
                  if (mounted)
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
                  if (mounted) {
                    setState(() => _isTesting = false);
                    if (success) {
                      ErrorDialog.showSuccess(
                        context,
                        'Connection successful!',
                      );
                    } else {
                      ErrorDialog.showSnackBar(
                        context,
                        'Connection failed. Check your key.',
                      );
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDefaultLanguage() {
    return _SettingsSection(
      title: AppStrings.defaultLanguage,
      icon: Icons.language_rounded,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            border: Border.all(color: AppColors.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _defaultLanguage,
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
              onChanged: (value) async {
                if (value != null) {
                  setState(() => _defaultLanguage = value);
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('default_language', value);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone() {
    return _SettingsSection(
      title: 'Data Management',
      icon: Icons.storage_rounded,
      children: [
        CustomButton(
          text: AppStrings.clearAllProjects,
          isOutlined: true,
          height: 40,
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder:
                  (_) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Clear All Projects?'),
                    content: const Text(
                      'This will delete all saved projects and cannot be undone.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Delete All',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
            );
            if (confirm == true) {
              await ProjectRepository().clearAll();
              if (mounted)
                ErrorDialog.showSuccess(context, 'All projects cleared');
            }
          },
        ),
      ],
    );
  }

  Widget _buildAbout() {
    return _SettingsSection(
      title: AppStrings.about,
      icon: Icons.info_outline_rounded,
      children: [
        ListTile(
          dense: true,
          title: Text(
            'Version',
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          trailing: Text(
            AppStrings.appVersion,
            style: GoogleFonts.poppins(color: AppColors.textHint, fontSize: 14),
          ),
        ),
        ListTile(
          dense: true,
          title: Text(
            AppStrings.privacyPolicy,
            style: GoogleFonts.poppins(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
          onTap: () {},
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
}
