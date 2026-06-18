import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

/// A single onboarding value-prop slide: an animated hero visual on top,
/// a gradient title, and a description.
///
/// Ambient motion in the [hero] loops continuously. The title and
/// description re-stagger in whenever the slide becomes active (driven by
/// [isActive]), and the hero/title shift slightly with [parallax] while the
/// user drags between slides.
class OnboardingPageWidget extends StatelessWidget {
  final Widget hero;
  final String title;
  final String description;

  /// Fractional distance of this page from the viewport center
  /// (0 = centered, ±1 = a full page away). Used for the parallax effect.
  final double parallax;

  /// Whether this is the currently visible page; drives entrance choreography.
  final bool isActive;

  const OnboardingPageWidget({
    super.key,
    required this.hero,
    required this.title,
    required this.description,
    this.parallax = 0,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingLG,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: Offset(parallax * -40, 0),
            child: SizedBox(height: 220, child: Center(child: hero)),
          ),
          const SizedBox(height: AppDimensions.paddingXXL),
          // Title + description re-animate each time the slide becomes active.
          Animate(
            key: ValueKey('onboarding-text-$isActive-$title'),
            effects: isActive
                ? const [
                    FadeEffect(duration: Duration(milliseconds: 450)),
                    SlideEffect(
                      begin: Offset(0, 0.2),
                      end: Offset.zero,
                      duration: Duration(milliseconds: 450),
                      curve: Curves.easeOut,
                    ),
                  ]
                : const [],
            child: Transform.translate(
              offset: Offset(parallax * -20, 0),
              child: Column(
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) =>
                        AppColors.primaryGradient.createShader(bounds),
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.paddingMD),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slide 1 hero: a sparkle over a caption bubble whose words pulse in.
class AiCaptionsHero extends StatelessWidget {
  const AiCaptionsHero({super.key});

  @override
  Widget build(BuildContext context) {
    const words = ['Add', 'AI', 'captions', 'instantly'];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.auto_awesome,
          size: 56,
          color: AppColors.primary,
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1.1, 1.1),
              duration: 1400.ms,
              curve: Curves.easeInOut,
            )
            .shimmer(
              duration: 1800.ms,
              color: AppColors.captionHighlight,
            ),
        const SizedBox(height: AppDimensions.paddingLG),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMD,
            vertical: AppDimensions.paddingSM,
          ),
          decoration: BoxDecoration(
            color: AppColors.captionBackground,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          child: Wrap(
            spacing: 6,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < words.length; i++)
                Text(
                  words[i],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: i == 1
                        ? AppColors.captionHighlight
                        : AppColors.textPrimary,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .fadeIn(
                      delay: (250 * i).ms,
                      duration: 350.ms,
                    )
                    .slideX(begin: 0.4, end: 0, duration: 350.ms)
                    .then(delay: (1200 - 250 * i).ms)
                    .fadeOut(duration: 400.ms),
            ],
          ),
        ),
      ],
    );
  }
}

/// Slide 2 hero: a stack of style-template chips with a looping shimmer.
class StylesHero extends StatelessWidget {
  const StylesHero({super.key});

  @override
  Widget build(BuildContext context) {
    const chips = <(String, Color)>[
      ('TikTok', AppColors.primary),
      ('YouTube', AppColors.error),
      ('Neon', AppColors.success),
      ('Minimal', AppColors.textSecondary),
      ('Bold', AppColors.warning),
      ('Instagram', AppColors.accent),
    ];
    return Shimmer.fromColors(
      baseColor: AppColors.textPrimary,
      highlightColor: AppColors.captionHighlight,
      period: const Duration(milliseconds: 2600),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: [
          for (var i = 0; i < chips.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMD,
                vertical: AppDimensions.paddingSM,
              ),
              decoration: BoxDecoration(
                color: chips[i].$2.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
                border: Border.all(
                  color: chips[i].$2.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                chips[i].$1,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.94, 0.94),
                  end: const Offset(1.04, 1.04),
                  delay: (180 * i).ms,
                  duration: 1300.ms,
                  curve: Curves.easeInOut,
                ),
        ],
      ),
    );
  }
}

/// Slide 3 hero: a video card whose caption "burns in", then floats up to share.
class ExportHero extends StatelessWidget {
  const ExportHero({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video frame.
          Container(
            width: 180,
            height: 120,
            decoration: BoxDecoration(
              gradient: AppColors.cardGradient,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
              border: Border.all(color: AppColors.divider),
            ),
            alignment: Alignment.bottomCenter,
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.captionBackground,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
              ),
              child: Text(
                'Captions burned in',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.captionHighlight,
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1))
                .then(delay: 1400.ms)
                .fadeOut(duration: 400.ms),
          ),
          // Share icon floating up.
          Positioned(
            top: 0,
            child: Icon(
              Icons.ios_share_rounded,
              size: 34,
              color: AppColors.primary,
            )
                .animate(onPlay: (c) => c.repeat())
                .fadeIn(delay: 700.ms, duration: 400.ms)
                .slideY(begin: 0.6, end: 0, duration: 700.ms)
                .then(delay: 700.ms)
                .fadeOut(duration: 500.ms),
          ),
        ],
      ),
    );
  }
}
