import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_repository.dart';
import '../../providers/export_provider.dart';
import '../../widgets/common/gradient_background.dart';
import '../../widgets/export/export_complete_widget.dart';
import '../../widgets/export/export_options_widget.dart';
import '../../widgets/export/export_progress_widget.dart';

/// Export screen with options for video, SRT, and VTT export.
class ExportScreen extends StatefulWidget {
  final String projectId;
  const ExportScreen({super.key, required this.projectId});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  final ProjectRepository _projectRepo = ProjectRepository();
  ProjectModel? _project;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final project = await _projectRepo.getProject(widget.projectId);
    if (mounted) {
      setState(() {
        _project = project;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _project == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Consumer<ExportProvider>(
            builder: (context, exportProv, _) {
              if (exportProv.exportState == ExportState.done) {
                return ExportCompleteWidget(exportProv: exportProv);
              }
              if (exportProv.isExporting) {
                return ExportProgressWidget(exportProv: exportProv);
              }
              return ExportOptionsWidget(project: _project!);
            },
          ),
        ),
      ),
    );
  }
}
