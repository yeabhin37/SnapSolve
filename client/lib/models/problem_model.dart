class Problem {
  final String id; // 문제 고유 ID (UUID)
  final String problemText; // 문제 지문 내용
  final List<String> choices; // 객관식 선지 리스트 (주관식일 경우 빈 리스트)
  final String? correctAnswer; // 정답
  final String? memo; // 사용자가 작성한 메모
  bool isWrongNote; // 오답노트(별표) 포함 여부 (UI에서 변경 가능하므로 final 아님)

  Problem({
    required this.id,
    required this.problemText,
    required this.choices,
    this.correctAnswer,
    this.isWrongNote = false,
    this.memo,
  });

  // JSON -> 객체 변환
  factory Problem.fromJson(Map<String, dynamic> json) {
    return Problem(
      id: json['id']?.toString() ?? '',
      problemText: json['problem'] ?? '문제 내용 없음',
      // 'choices'가 null이면 빈 리스트, 있으면 String 리스트로 변환
      choices: json['choices'] != null
          ? List<String>.from(json['choices'])
          : [],
      // 서버 필드명이 'answer' 또는 'correct_answer'일 수 있음을 대응
      correctAnswer: json['answer'] ?? json['correct_answer'],
      isWrongNote: json['is_wrong_note'] ?? false,
      memo: json['memo'],
    );
  }
}
