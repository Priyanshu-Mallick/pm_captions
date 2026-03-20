import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../providers/caption_provider.dart';
import '../../providers/style_provider.dart';
import '../../providers/video_provider.dart';
import '../../widgets/editor/captions_list_panel.dart';
import '../../widgets/editor/style_panel_widget.dart';
import '../../widgets/editor/timing_panel_widget.dart';
import '../../widgets/editor/video_preview_widget.dart';

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
          const Expanded(flex: 7, child: VideoPreviewWidget()),
          _buildTabBar(),
          Expanded(
            flex: 3,
            child: TabBarView(
              controller: _tabController,
              children: const [
                CaptionsListPanel(),
                StylePanelWidget(),
                TimingPanelWidget(),
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
}
