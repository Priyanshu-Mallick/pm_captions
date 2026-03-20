import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart' as vp;
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/time_formatter.dart';
import '../../providers/caption_provider.dart';
import '../../providers/style_provider.dart';
import '../../providers/video_provider.dart';
import '../caption/animated_caption.dart';

class VideoPreviewWidget extends StatelessWidget {
  const VideoPreviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<VideoProvider, CaptionProvider, StyleProvider>(
      builder: (context, videoProv, captionProv, styleProv, _) {
        if (!videoProv.isInitialized || videoProv.videoController == null) {
          return Container(
            color: Colors.black,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        final currentCaption = captionProv.getCaptionAtPosition(
          videoProv.currentPosition,
        );
        final aspectRatio = videoProv.videoController!.value.aspectRatio;
        return GestureDetector(
          onTap: () => videoProv.togglePlayPause(),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        vp.VideoPlayer(videoProv.videoController!),
                        if (currentCaption != null)
                          Align(
                            alignment: Alignment(
                              0,
                              (styleProv.currentStyle.verticalPosition * 2) -
                                  1.0,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: AnimatedCaption(
                                key: ValueKey(
                                  Object.hash(
                                    currentCaption.id,
                                    currentCaption.text,
                                  ),
                                ),
                                caption: currentCaption,
                                style: styleProv.currentStyle,
                                currentPosition: videoProv.currentPosition,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!videoProv.isPlaying)
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.overlay,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _ScrubberWidget(videoProv: videoProv),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ScrubberWidget extends StatelessWidget {
  final VideoProvider videoProv;

  const _ScrubberWidget({required this.videoProv});

  @override
  Widget build(BuildContext context) {
    final totalMs = videoProv.videoDuration.inMilliseconds.toDouble();
    final currentMs = videoProv.currentPosition.inMilliseconds.toDouble();
    return Container(
      color: Colors.black54,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text(
            TimeFormatter.durationToDisplay(videoProv.currentPosition),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 11),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.divider,
                thumbColor: AppColors.primary,
              ),
              child: Slider(
                value: totalMs > 0 ? currentMs.clamp(0, totalMs) : 0,
                min: 0,
                max: totalMs > 0 ? totalMs : 1,
                onChanged:
                    (v) => videoProv.seekTo(Duration(milliseconds: v.round())),
              ),
            ),
          ),
          Text(
            TimeFormatter.durationToDisplay(videoProv.videoDuration),
            style: GoogleFonts.poppins(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
