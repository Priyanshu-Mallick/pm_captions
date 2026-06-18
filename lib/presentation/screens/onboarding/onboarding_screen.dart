import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/onboarding/onboarding_api_key_step.dart';
import '../../widgets/onboarding/onboarding_page_widget.dart';

/// One-time first-launch onboarding: three animated value-prop slides plus a
/// final Groq API key setup step. Owns marking `seen_onboarding = true`.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  /// Total pages: 3 value-prop slides + 1 API key step.
  static const int _pageCount = 4;
  static const int _keyStepIndex = _pageCount - 1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final page = (_controller.page ?? 0).round();
    if (page != _currentPage) {
      setState(() => _currentPage = page);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    if (mounted) context.go('/home');
  }

  void _nextPage() {
    if (_currentPage < _keyStepIndex) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  double _parallaxFor(int index) {
    if (!_controller.hasClients || _controller.position.haveDimensions) {
      final page = _controller.hasClients
          ? (_controller.page ?? _currentPage.toDouble())
          : _currentPage.toDouble();
      return (page - index).clamp(-1.0, 1.0);
    }
    return (_currentPage - index).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final onLastSlide = _currentPage == _keyStepIndex - 1;
    final onKeyStep = _currentPage == _keyStepIndex;

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Skip (hidden on the key step, which has its own skip).
              Align(
                alignment: Alignment.centerRight,
                child: AnimatedOpacity(
                  opacity: onKeyStep ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: TextButton(
                    onPressed: onKeyStep ? null : _finishOnboarding,
                    child: Text(
                      AppStrings.skip,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  children: [
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) => OnboardingPageWidget(
                        hero: const AiCaptionsHero(),
                        title: AppStrings.onboardingTitle1,
                        description: AppStrings.onboardingDesc1,
                        parallax: _parallaxFor(0),
                        isActive: _currentPage == 0,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) => OnboardingPageWidget(
                        hero: const StylesHero(),
                        title: AppStrings.onboardingTitle2,
                        description: AppStrings.onboardingDesc2,
                        parallax: _parallaxFor(1),
                        isActive: _currentPage == 1,
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (_, __) => OnboardingPageWidget(
                        hero: const ExportHero(),
                        title: AppStrings.onboardingTitle3,
                        description: AppStrings.onboardingDesc3,
                        parallax: _parallaxFor(2),
                        isActive: _currentPage == 2,
                      ),
                    ),
                    OnboardingApiKeyStep(
                      onComplete: _finishOnboarding,
                      onSkip: _finishOnboarding,
                    ),
                  ],
                ),
              ),
              _buildDots(),
              const SizedBox(height: AppDimensions.paddingLG),
              // Next / Get Started shown only on the value-prop slides; the key
              // step provides its own Save & Continue / Skip actions.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paddingLG,
                ),
                child: AnimatedOpacity(
                  opacity: onKeyStep ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: onKeyStep,
                    child: CustomButton(
                      text: onLastSlide
                          ? AppStrings.getStarted
                          : AppStrings.next,
                      onPressed: _nextPage,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppDimensions.paddingXL),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pageCount, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.primaryGradient : null,
            color: isActive ? null : AppColors.divider,
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          ),
        );
      }),
    );
  }
}
