/// Domain entity representing a project.
class ProjectEntity {
  final String id;
  final String name;
  final String videoPath;
  final Duration videoDuration;
  final DateTime createdAt;

  const ProjectEntity({
    required this.id,
    required this.name,
    required this.videoPath,
    required this.videoDuration,
    required this.createdAt,
  });
}
