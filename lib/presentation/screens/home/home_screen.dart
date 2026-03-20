import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/home/action_buttons_widget.dart';
import '../../widgets/home/hero_card_widget.dart';
import '../../widgets/home/recent_projects_widget.dart';

/// Home screen with hero section, action buttons, and recent projects.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
                _buildAppBar(),
                const SizedBox(height: AppDimensions.paddingLG),
                const HeroCardWidget(),
                const SizedBox(height: AppDimensions.paddingLG),
                const ActionButtonsWidget(),
                const SizedBox(height: AppDimensions.paddingXL),
                const RecentProjectsWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.hardEdge,
          child: Image.asset('assets/logo/pm.png', fit: BoxFit.cover),
        ),
        const SizedBox(width: 12),
        Text(
          AppStrings.appName,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(
            Icons.settings_rounded,
            color: AppColors.textSecondary,
          ),
          onPressed: () => context.push('/settings'),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }
}
