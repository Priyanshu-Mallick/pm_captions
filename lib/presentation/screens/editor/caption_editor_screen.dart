import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart' as vp;

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../data/models/caption_model.dart';
import '../../../data/models/caption_style_model.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../providers/caption_provider.dart';
import '../../providers/style_provider.dart';
import '../../providers/video_provider.dart';
import '../../widgets/caption/animated_caption.dart';

class CaptionEditorScreen extends StatefulWidget {
  final String projectId;
  const CaptionEditorScreen({super.key, required this.projectId});

  @override
  State<CaptionEditorScreen> createState() => _CaptionEditorScreenState();
}

class _CaptionEditorScreenState extends State<CaptionEditorScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ProjectRepository _projectRepo = ProjectRepository();
  ProjectModel? _project;
  bool _isLoading = true;
  Timer? _autoSaveTimer;
  final ScrollController _captionScrollController = ScrollController();
  int _lastActiveIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProject();
    _autoSaveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _saveProject(),
    );
  }

  Future<void> _loadProject() async {
    final project = await _projectRepo.getProject(widget.projectId);
    if (project != null && mounted) {
      final vp = context.read<VideoProvider>();
      final cp = context.read<CaptionProvider>();
      final sp = context.read<StyleProvider>();
      await vp.initializeVideo(project.videoPath);
      cp.setCaptions(project.captions);
      sp.setStyle(project.style);
      setState(() {
        _project = project;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProject() async {
    if (_project == null) return;
    final captions = context.read<CaptionProvider>().captions;
    final style = context.read<StyleProvider>().currentStyle;
    final updated = _project!.copyWith(
      captions: captions,
      style: style,
      updatedAt: DateTime.now(),
    );
    await _projectRepo.updateProject(updated, captions);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _tabController.dispose();
    _captionScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(flex: 7, child: _buildVideoPreview()),
          _buildTabBar(),
          Expanded(
            flex: 3,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCaptionsList(),
                _buildStylePanel(),
                _buildTimingPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios),
        onPressed: () async {
          await _saveProject();
          if (mounted) context.go('/home');
        },
      ),
      title: Text(
        _project?.name ?? AppStrings.captions,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      actions: [
        Consumer<CaptionProvider>(
          builder:
              (_, cp, __) => IconButton(
                icon: Icon(
                  Icons.undo,
                  color:
                      cp.canUndo ? AppColors.textPrimary : AppColors.textHint,
                ),
                onPressed: cp.canUndo ? () => cp.undo() : null,
              ),
        ),
        Consumer<CaptionProvider>(
          builder:
              (_, cp, __) => IconButton(
                icon: Icon(
                  Icons.redo,
                  color:
                      cp.canRedo ? AppColors.textPrimary : AppColors.textHint,
                ),
                onPressed: cp.canRedo ? () => cp.redo() : null,
              ),
        ),
        TextButton(
          onPressed: () async {
            // Await the DB write so the export screen always reloads
            // the latest captions — prevents a race condition.
            await _saveProject();
            if (mounted) context.push('/export/${widget.projectId}');
          },
          child: Text(
            AppStrings.exportVideo,
            style: GoogleFonts.poppins(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
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
        // Use the video's natural aspect ratio; wrap in FittedBox so the video
        // is never squished – unused space stays black.
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
                                // ValueKey on id+text forces Flutter to tear
                                // down and re-animate whenever text is edited.
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
                child: _buildScrubber(videoProv),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScrubber(VideoProvider videoProv) {
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

  Widget _buildTabBar() {
    return Container(
      color: AppColors.surface,
      child: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: AppStrings.captions),
          Tab(text: AppStrings.style),
          Tab(text: AppStrings.timing),
        ],
      ),
    );
  }

  Widget _buildCaptionsList() {
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
              // item width ~ 180 + margin
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
                            child: const _CaptionEditPage(),
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

  Widget _buildStylePanel() {
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
              'Text Color',
              sp.currentStyle.textColor,
              sp.updateTextColor,
            ),
            _colorRow(
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

  Widget _colorRow(String label, Color color, ValueChanged<Color> onChanged) {
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

  Widget _buildTimingPanel() {
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

class _CaptionEditPage extends StatelessWidget {
  const _CaptionEditPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(
          'Edit Captions',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Apply',
              style: GoogleFonts.poppins(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CaptionProvider>(
        builder: (context, cp, _) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cp.captions.length,
            itemBuilder: (context, index) {
              final c = cp.captions[index];
              return _EditableCaptionTile(
                caption: c,
                onTextChanged: (text) => cp.updateCaptionText(index, text),
                onDelete: () => cp.deleteCaption(index),
              );
            },
          );
        },
      ),
    );
  }
}

class _EditableCaptionTile extends StatefulWidget {
  final CaptionModel caption;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onDelete;

  const _EditableCaptionTile({
    required this.caption,
    required this.onTextChanged,
    required this.onDelete,
  });

  @override
  State<_EditableCaptionTile> createState() => _EditableCaptionTileState();
}

class _EditableCaptionTileState extends State<_EditableCaptionTile> {
  late TextEditingController _tc;

  @override
  void initState() {
    super.initState();
    _tc = TextEditingController(text: widget.caption.text);
  }

  @override
  void didUpdateWidget(covariant _EditableCaptionTile old) {
    super.didUpdateWidget(old);
    if (old.caption.text != widget.caption.text &&
        _tc.text != widget.caption.text) {
      _tc.text = widget.caption.text;
    }
  }

  @override
  void dispose() {
    _tc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${TimeFormatter.durationToDisplay(widget.caption.startTime)} - '
                  '${TimeFormatter.durationToDisplay(widget.caption.endTime)}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _tc,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: null,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    hintText: 'Enter caption text',
                  ),
                  onChanged: widget.onTextChanged,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: widget.onDelete,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
