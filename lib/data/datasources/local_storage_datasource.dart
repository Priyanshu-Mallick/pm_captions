import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/caption_model.dart';
import '../models/project_model.dart';
import '../models/word_timestamp_model.dart';

/// SQLite database helper for persisting projects and captions.
///
/// Uses the singleton pattern to ensure a single database connection
/// throughout the app lifecycle.
class LocalStorageDatasource {
  static final _log = Logger();
  static LocalStorageDatasource? _instance;
  static Database? _database;

  LocalStorageDatasource._();

  /// Returns the singleton instance.
  static LocalStorageDatasource get instance {
    _instance ??= LocalStorageDatasource._();
    return _instance!;
  }

  /// Returns the database, initializing it if necessary.
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initializes the SQLite database.
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'ai_captions.db');

    _log.i('Initializing database at: $path');

    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  /// Creates the database tables.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        videoPath TEXT NOT NULL,
        thumbnailPath TEXT DEFAULT '',
        videoDuration INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        isExported INTEGER DEFAULT 0,
        exportPath TEXT,
        styleJson TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE captions (
        id TEXT PRIMARY KEY,
        projectId TEXT NOT NULL,
        text TEXT NOT NULL,
        startMs INTEGER NOT NULL,
        endMs INTEGER NOT NULL,
        wordsJson TEXT,
        isEdited INTEGER DEFAULT 0,
        displayOrder INTEGER DEFAULT 0,
        FOREIGN KEY (projectId) REFERENCES projects(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_captions_project ON captions(projectId)
    ''');

    _log.i('Database tables created');
  }

  // ── Project Operations ──────────────────────────────────────────

  /// Inserts a new project into the database.
  Future<String> insertProject(ProjectModel project) async {
    final db = await database;
    await db.insert(
      'projects',
      project.toDbMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _log.i('Inserted project: ${project.id}');
    return project.id;
  }

  /// Updates an existing project.
  Future<void> updateProject(ProjectModel project) async {
    final db = await database;
    await db.update(
      'projects',
      project.toDbMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );
    _log.i('Updated project: ${project.id}');
  }

  /// Deletes a project and its captions.
  Future<void> deleteProject(String id) async {
    final db = await database;
    await db.delete('captions', where: 'projectId = ?', whereArgs: [id]);
    await db.delete('projects', where: 'id = ?', whereArgs: [id]);
    _log.i('Deleted project: $id');
  }

  /// Returns all projects ordered by most recently updated.
  Future<List<ProjectModel>> getAllProjects() async {
    final db = await database;
    final maps = await db.query('projects', orderBy: 'updatedAt DESC');
    return maps.map((m) => ProjectModel.fromDbMap(m)).toList();
  }

  /// Returns a single project by its ID.
  Future<ProjectModel?> getProject(String id) async {
    final db = await database;
    final maps = await db.query('projects', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return ProjectModel.fromDbMap(maps.first);
  }

  // ── Caption Operations ──────────────────────────────────────────

  /// Inserts a list of captions for a project.
  Future<void> insertCaptions(
    List<CaptionModel> captions,
    String projectId,
  ) async {
    final db = await database;
    final batch = db.batch();

    for (var i = 0; i < captions.length; i++) {
      batch.insert(
        'captions',
        captions[i].toDbMap(projectId, i),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    _log.i('Inserted ${captions.length} captions for project: $projectId');
  }

  /// Updates a single caption.
  Future<void> updateCaption(CaptionModel caption, String projectId) async {
    final db = await database;
    await db.update(
      'captions',
      caption.toDbMap(projectId, 0), // displayOrder handled separately
      where: 'id = ?',
      whereArgs: [caption.id],
    );
  }

  /// Returns all captions for a project, ordered by display order.
  Future<List<CaptionModel>> getCaptionsForProject(String projectId) async {
    final db = await database;
    final maps = await db.query(
      'captions',
      where: 'projectId = ?',
      whereArgs: [projectId],
      orderBy: 'displayOrder ASC',
    );

    return maps.map((m) {
      return CaptionModel(
        id: m['id'] as String,
        text: m['text'] as String? ?? '',
        words: _parseWordsJson(m['wordsJson'] as String?),
        startTime: Duration(milliseconds: m['startMs'] as int? ?? 0),
        endTime: Duration(milliseconds: m['endMs'] as int? ?? 0),
        isEdited: (m['isEdited'] as int? ?? 0) == 1,
      );
    }).toList();
  }

  /// Deletes all captions for a project and re-inserts the new list.
  Future<void> replaceCaptions(
    List<CaptionModel> captions,
    String projectId,
  ) async {
    final db = await database;
    await db.delete('captions', where: 'projectId = ?', whereArgs: [projectId]);
    await insertCaptions(captions, projectId);
  }

  /// Parses the stored JSON words string back into WordTimestampModel list.
  List<WordTimestampModel> _parseWordsJson(String? json) {
    if (json == null || json.isEmpty) return [];
    try {
      final decoded = jsonDecode(json) as List;
      return decoded
          .map((w) => WordTimestampModel.fromJson(w as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log.w('Failed to parse words JSON', error: e);
      return [];
    }
  }

  /// Deletes all data from the database.
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('captions');
    await db.delete('projects');
    _log.i('All data cleared');
  }

  /// Closes the database connection.
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    _log.i('Database closed');
  }
}
