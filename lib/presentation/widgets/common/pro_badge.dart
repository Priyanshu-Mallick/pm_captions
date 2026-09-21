import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gold "PRO" chip used to mark subscription-only features.
class ProBadge extends StatelessWidget {
  /// Shrinks the badge for dense spots like template thumbnails.
  final bool compact;

  const ProBadge({super.key, this.compact = false});

  static const LinearGradient _gold = LinearGradient(
    colors: [Color(0xFFFFD983), Color(0xFFD4AF37)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 8,
        vertical: compact ? 1.5 : 3,
      ),
      decoration: BoxDecoration(
        gradient: _gold,
        borderRadius: BorderRadius.circular(compact ? 5 : 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: compact ? 9 : 13,
            color: const Color(0xFF3A2B00),
          ),
          SizedBox(width: compact ? 2 : 4),
          Text(
            'PRO',
            style: GoogleFonts.poppins(
              fontSize: compact ? 8 : 11,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: 0.4,
              color: const Color(0xFF3A2B00),
            ),
          ),
        ],
      ),
    );
  }
}
