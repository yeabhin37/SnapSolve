class Folder {
  final int id; // 폴더 고유 번호 (PK)
  final String name; // 폴더 이름
  final String color; // 폴더 색
  final int problemCount; // 폴더에 포함된 문제 수

  Folder({
    required this.id,
    required this.name,
    required this.color,
    required this.problemCount,
  });

  // JSON 데이터를 객체로 변환하는 팩토리 생성자
  factory Folder.fromJson(Map<String, dynamic> json) {
    return Folder(
      id: json['id'] ?? 0,
      name: json['name'] ?? '이름 없음',
      // 서버에서 색상이 없을 경우 기본 네이비 색상 사용
      color: json['color'] ?? '0xFF1E2B58',
      problemCount: json['problem_count'] ?? 0,
    );
  }
}
