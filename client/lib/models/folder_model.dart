class Folder {
  final String name;
  final int problemCount;

  Folder({required this.name, required this.problemCount});

  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      name: json['name'] ?? '이름 없음',
      problemCount: json['problem_count'] ?? 0,
    );
  }
}
