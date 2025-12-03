class Folder {
  final int id;
  final String name;
  final String color;
  final int problemCount;

  Folder({
    required this.id,
    required this.name,
    required this.color,
    required this.problemCount,
  });

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] ?? 0,
      name: json['name'] ?? '이름 없음',
      color: json['color'] ?? '0xFF1E2B58',
      problemCount: json['problem_count'] ?? 0,
    );
  }
}
