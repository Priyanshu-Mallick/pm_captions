import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/processing_provider.dart';

class ProcessingStepsWidget extends StatelessWidget {
  final ProcessingProvider provider;

  const ProcessingStepsWidget({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _StepItem(
          label: AppStrings.extractingAudio,
          isActive: provider.currentState == ProcessingState.extractingAudio,
          isDone:
              provider.currentState.index >
              ProcessingState.extractingAudio.index,
        ),
        const SizedBox(height: 12),
        _StepItem(
          label: AppStrings.transcribingSpeech,
          isActive: provider.currentState == ProcessingState.transcribing,
          isDone:
              provider.currentState.index > ProcessingState.transcribing.index,
        ),
        const SizedBox(height: 12),
        _StepItem(
          label: AppStrings.generatingCaptions,
          isActive: provider.currentState == ProcessingState.groupingCaptions,
          isDone:
              provider.currentState.index >
              ProcessingState.groupingCaptions.index,
        ),
        const SizedBox(height: 12),
        _StepItem(
          label: AppStrings.finalizing,
          isActive: provider.currentState == ProcessingState.done,
          isDone: provider.currentState == ProcessingState.done,
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }
}

class _StepItem extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepItem({
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isDone
                    ? AppColors.success
                    : isActive
                    ? AppColors.primary
                    : AppColors.surface,
            border: Border.all(
              color:
                  isDone
                      ? AppColors.success
                      : isActive
                      ? AppColors.primary
                      : AppColors.divider,
            ),
          ),
          child:
              isDone
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : isActive
                  ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                  : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color:
                  isDone || isActive
                      ? AppColors.textPrimary
                      : AppColors.textHint,
            ),
          ),
        ),
      ],
    );
  }
}
