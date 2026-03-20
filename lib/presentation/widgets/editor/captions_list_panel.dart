import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_formatter.dart';
import '../../providers/caption_provider.dart';
import '../../providers/video_provider.dart';
import '../../screens/editor/caption_edit_page.dart';

class CaptionsListPanel extends StatefulWidget {
  const CaptionsListPanel({super.key});

  @override
  State<CaptionsListPanel> createState() => _CaptionsListPanelState();
}

class _CaptionsListPanelState extends State<CaptionsListPanel> {
  final ScrollController _captionScrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void dispose() {
    _captionScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<CaptionProvider, VideoProvider>(
      builder: (context, captionProv, videoProv, _) {
        if (captionProv.captions.isEmpty) {
          return Center(
            child: Text(
              'No captions yet',
              style: GoogleFonts.poppins(color: AppColors.textHint),
            ),
          );
        }
        final int activeIndex =
            captionProv.getCaptionIndexAtPosition(videoProv.currentPosition) ??
            -1;

        if (activeIndex != _lastActiveIndex && activeIndex != -1) {
          _lastActiveIndex = activeIndex;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_captionScrollController.hasClients) {
              _captionScrollController.animateTo(
                activeIndex * 196.0,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          });
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _captionScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(8),
                itemCount: captionProv.captions.length,
                itemBuilder: (context, index) {
                  final c = captionProv.captions[index];
                  final isActive =
                      index ==
                      (captionProv.selectedCaptionIndex ?? activeIndex);
                  return GestureDetector(
                    onTap: () async {
                      captionProv.selectCaption(index);
                      await videoProv.pause();
                      await videoProv.seekTo(
                        c.startTime + const Duration(milliseconds: 10),
                      );
                    },
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.only(
                        right: 16,
                        top: 16,
                        bottom: 16,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isActive
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isActive
                                  ? AppColors.primary.withValues(alpha: 0.5)
                                  : AppColors.divider,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${TimeFormatter.durationToDisplay(c.startTime)} - '
                            '${TimeFormatter.durationToDisplay(c.endTime)}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              c.text,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChangeNotifierProvider.value(
                            value: context.read<CaptionProvider>(),
                            child: const CaptionEditPage(),
                          ),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Edit Captions',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
