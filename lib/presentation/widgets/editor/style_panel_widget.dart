import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/caption_style_model.dart';
import '../../providers/style_provider.dart';

class StylePanelWidget extends StatelessWidget {
  const StylePanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StyleProvider>(
      builder: (context, sp, _) {
        return ListView(
          padding: const EdgeInsets.all(AppDimensions.paddingMD),
          children: [
            Text(
              AppStrings.templates,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children:
                    CaptionTemplate.values.map((t) {
                      final sel = sp.currentStyle.predefinedTemplate == t;
                      return GestureDetector(
                        onTap: () => sp.applyTemplate(t),
                        child: Container(
                          width: 90,
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                sel
                                    ? AppColors.primary.withValues(alpha: 0.2)
                                    : AppColors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  sel ? AppColors.primary : AppColors.divider,
                              width: sel ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              t.name,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color:
                                    sel
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
            const Divider(color: AppColors.divider, height: 32),
            _slider(
              'Font Size: ${sp.currentStyle.fontSize.round()}',
              sp.currentStyle.fontSize,
              AppDimensions.captionMinFontSize,
              AppDimensions.captionMaxFontSize,
              sp.updateFontSize,
            ),
            _colorRow(
              context,
              'Text Color',
              sp.currentStyle.textColor,
              sp.updateTextColor,
            ),
            _colorRow(
              context,
              'Highlight',
              sp.currentStyle.highlightColor,
              sp.updateHighlightColor,
            ),
            _slider(
              'Opacity: ${(sp.currentStyle.backgroundOpacity * 100).round()}%',
              sp.currentStyle.backgroundOpacity,
              0,
              1,
              sp.updateBackgroundOpacity,
            ),
            _slider(
              'Stroke: ${sp.currentStyle.strokeWidth.toStringAsFixed(1)}',
              sp.currentStyle.strokeWidth,
              0,
              5,
              sp.updateStrokeWidth,
            ),
            _slider(
              'Position: ${(sp.currentStyle.verticalPosition * 100).round()}%',
              sp.currentStyle.verticalPosition,
              0.1,
              0.95,
              sp.updatePosition,
            ),
            _slider(
              'Max Lines: ${sp.currentStyle.maxLines}',
              sp.currentStyle.maxLines.toDouble(),
              1,
              2,
              (v) => sp.updateMaxLines(v.round()),
            ),
            SwitchListTile(
              title: Text(
                AppStrings.allCaps,
                style: GoogleFonts.poppins(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
              value: sp.currentStyle.isAllCaps,
              onChanged: (_) => sp.toggleAllCaps(),
              activeColor: AppColors.primary,
            ),
          ],
        );
      },
    );
  }

  Widget _slider(
    String label,
    double val,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Slider(
            value: val.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _colorRow(
    BuildContext context,
    String label,
    Color color,
    ValueChanged<Color> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap:
                () => showDialog(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: Text(label),
                        content: SingleChildScrollView(
                          child: ColorPicker(
                            pickerColor: color,
                            onColorChanged: onChanged,
                            enableAlpha: false,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                ),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
