import 'package:logger/logger.dart';

import '../datasources/local_storage_datasource.dart';
import '../models/caption_model.dart';
import '../models/project_model.dart';

/// Repository for project persistence operations.
class ProjectRepository {
  final LocalStorageDatasource _localStorage;
  static final _log = Logger();

  ProjectRepository({LocalStorageDatasource? localStorage})
    : _localStorage = localStorage ?? LocalStorageDatasource.instance;

  /// Saves a new project with its captions.
  Future<String> saveProject(
    ProjectModel project,
    List<CaptionModel> captions,
  ) async {
    _log.i('Saving project: ${project.id}');
    final id = await _localStorage.insertProject(project);
    await _localStorage.insertCaptions(captions, project.id);
    return id;
  }

  /// Updates an existing project and its captions.
  Future<void> updateProject(
    ProjectModel project,
    List<CaptionModel> captions,
  ) async {
    _log.i('Updating project: ${project.id}');
    await _localStorage.updateProject(project);
    await _localStorage.replaceCaptions(captions, project.id);
  }

  /// Deletes a project.
  Future<void> deleteProject(String id) async {
    _log.i('Deleting project: $id');
    await _localStorage.deleteProject(id);
  }

  /// Returns all projects.
  Future<List<ProjectModel>> getAllProjects() async {
    final projects = await _localStorage.getAllProjects();
    // Load captions for each project
    final result = <ProjectModel>[];
    for (final project in projects) {
      final captions = await _localStorage.getCaptionsForProject(project.id);
      result.add(project.copyWith(captions: captions));
    }
    return result;
  }

  /// Returns a single project with its captions.
  Future<ProjectModel?> getProject(String id) async {
    final project = await _localStorage.getProject(id);
    if (project == null) return null;
    final captions = await _localStorage.getCaptionsForProject(id);
    return project.copyWith(captions: captions);
  }

  /// Clears all stored projects and captions.
  Future<void> clearAll() async {
    _log.w('Clearing all projects');
    await _localStorage.clearAll();
  }
}
