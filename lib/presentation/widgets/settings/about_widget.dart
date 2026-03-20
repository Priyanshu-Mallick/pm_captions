import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import 'settings_section_widget.dart';

class AboutWidget extends StatelessWidget {
  const AboutWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SettingsSectionWidget(
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
