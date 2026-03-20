import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

class ApiKeySectionWidget extends StatefulWidget {
  final TextEditingController apiKeyController;
  final ValueChanged<String> onChanged;

  const ApiKeySectionWidget({
    super.key,
    required this.apiKeyController,
    required this.onChanged,
  });

  @override
  State<ApiKeySectionWidget> createState() => _ApiKeySectionWidgetState();
}

class _ApiKeySectionWidgetState extends State<ApiKeySectionWidget> {
  bool _obscureApiKey = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.apiKey,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: widget.apiKeyController,
          obscureText: _obscureApiKey,
          style: GoogleFonts.poppins(
            color: AppColors.textPrimary,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: AppStrings.apiKeyHint,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureApiKey
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
              ),
              onPressed: () {
                setState(() => _obscureApiKey = !_obscureApiKey);
              },
            ),
          ),
          onChanged: widget.onChanged,
        ),
      ],
    );
  }
}
