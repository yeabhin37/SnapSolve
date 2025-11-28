class Problem {
  final String id;
  final String problemText;
  final List<String> choices;
  final String? correctAnswer; // 풀이 전에는 정답을 모를 수도 있음

  Problem({
    required this.id,
    required this.problemText,
    required this.choices,
    this.correctAnswer,
  });

  // JSON 데이터를 Dart 객체로 변환
  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      id: json['id']?.toString() ?? '',
      problemText: json['problem'] ?? '문제 내용 없음',
      // choices가 null이면 빈 리스트, 있으면 문자열 리스트로 변환
      choices: json['choices'] != null
          ? List<String>.from(json['choices'])
          : [],
      correctAnswer: json['answer'] ?? json['correct_answer'],
    );
  }
}
