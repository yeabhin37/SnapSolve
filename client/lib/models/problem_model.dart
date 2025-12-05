class Problem {
  final String id;
  final String problemText;
  final List<String> choices;
  final String? correctAnswer;
  final String? memo;
  bool isWrongNote;

  Problem({
    required this.id,
    required this.problemText,
    required this.choices,
    this.correctAnswer,
    this.isWrongNote = false,
    this.memo,
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
      isWrongNote: json['is_wrong_note'] ?? false,
      memo: json['memo'],
    );
  }
}
