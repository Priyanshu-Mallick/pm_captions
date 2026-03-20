import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_formatter.dart';
import '../../providers/caption_provider.dart';
import '../../providers/video_provider.dart';

class TimingPanelWidget extends StatelessWidget {
  const TimingPanelWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<CaptionProvider, VideoProvider>(
      builder: (context, captionProv, videoProv, _) {
        if (captionProv.captions.isEmpty) {
          return Center(
            child: Text(
              'No captions',
              style: GoogleFonts.poppins(color: AppColors.textHint),
            ),
          );
        }
        final totalMs = videoProv.videoDuration.inMilliseconds.toDouble();
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: captionProv.captions.length,
          itemBuilder: (context, index) {
            final c = captionProv.captions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Start:',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: c.startTime.inMilliseconds.toDouble().clamp(
                            0,
                            totalMs > 0 ? totalMs : 1,
                          ),
                          min: 0,
                          max: totalMs > 0 ? totalMs : 1,
                          onChanged:
                              (v) => captionProv.updateTimestamps(
                                index,
                                Duration(milliseconds: v.round()),
                                c.endTime,
                              ),
                        ),
                      ),
                      Text(
                        TimeFormatter.durationToDisplay(c.startTime),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'End:',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textHint,
                        ),
                      ),
                      Expanded(
                        child: Slider(
                          value: c.endTime.inMilliseconds.toDouble().clamp(
                            0,
                            totalMs > 0 ? totalMs : 1,
                          ),
                          min: 0,
                          max: totalMs > 0 ? totalMs : 1,
                          onChanged:
                              (v) => captionProv.updateTimestamps(
                                index,
                                c.startTime,
                                Duration(milliseconds: v.round()),
                              ),
                        ),
                      ),
                      Text(
                        TimeFormatter.durationToDisplay(c.endTime),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
