import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import 'settings_section_widget.dart';

class LanguageConfigWidget extends StatefulWidget {
  const LanguageConfigWidget({super.key});

  @override
  State<LanguageConfigWidget> createState() => _LanguageConfigWidgetState();
}

class _LanguageConfigWidgetState extends State<LanguageConfigWidget> {
  String _defaultLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('default_language') ?? 'en';
    if (mounted) {
      setState(() {
        _defaultLanguage = lang;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWidget(
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
}
