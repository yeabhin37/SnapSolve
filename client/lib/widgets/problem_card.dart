import 'package:flutter/material.dart';
import '../models/problem_model.dart';

class ProblemCard extends StatelessWidget {
  final Problem problem; // 표시할 문제 데이터
  final Map<String, String> userAnswers; // 사용자가 선택한 답 목록 (Key: 문제ID, Value: 답)
  final bool isAnswerChecked; // 정답 확인 모드 여부 (채점 후 True)
  final Function(String problemId, String answer)
  onAnswerSelected; // 답 선택 시 호출되는 콜백

  const ProblemCard({
    super.key,
    required this.problem,
    required this.userAnswers,
    required this.isAnswerChecked,
    required this.onAnswerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 문제 지문 영역 (회색 박스)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFFEBEFF5), // 연한 회색 배경
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              problem.problemText,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E2B58),
              ),
            ),
          ),
          const SizedBox(height: 30),

          // 2. 객관식 선지 목록 렌더링
          if (problem.choices.isNotEmpty)
            ...problem.choices.asMap().entries.map((entry) {
              final idx = entry.key + 1; // 1부터 시작하는 인덱스
              final text = entry.value;
              final choiceNumStr = idx.toString(); // "1", "2"...

              // 현재 이 선지가 사용자에 의해 선택되었는지 확인
              final isSelected = userAnswers[problem.id] == choiceNumStr;

              // ------ 스타일링 로직 (채점 전/후 분기) ------
              Color borderColor = Colors.transparent;
              Color bgColor = Colors.transparent;
              Color iconColor = Colors.grey.shade300;
              IconData iconData = Icons.check_box_outline_blank;

              if (isAnswerChecked) {
                // [채점 후] 정답 및 오답 표시
                final isAnswer = problem.correctAnswer == choiceNumStr;

                if (isAnswer) {
                  // 실제 정답인 선지 (초록색 강조)
                  borderColor = const Color(0xFF2EBA9F);
                  bgColor = const Color(0xFF2EBA9F).withOpacity(0.1);
                  iconColor = const Color(0xFF2EBA9F);
                  iconData = Icons.check_box;
                } else if (isSelected && !isAnswer) {
                  // 사용자가 선택했으나 틀린 선지 (빨간색 강조)
                  borderColor = Colors.red.shade300;
                  bgColor = Colors.red.withOpacity(0.05);
                  iconColor = Colors.red;
                  iconData = Icons.close; // X 아이콘
                }
              } else {
                // [풀이 중] 선택된 선지만 강조
                if (isSelected) {
                  borderColor = const Color(0xFF2EBA9F); // 민트색 테두리
                  bgColor = const Color(0xFF2EBA9F).withOpacity(0.05);
                  iconColor = const Color(0xFF2EBA9F);
                  iconData = Icons.check_box;
                }
              }

              return GestureDetector(
                // 채점 후에는 답을 변경할 수 없도록 터치 차단
                onTap: isAnswerChecked
                    ? null
                    : () => onAnswerSelected(problem.id, choiceNumStr),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(
                      // 테두리 색상 결정
                      color:
                          isAnswerChecked && borderColor == Colors.transparent
                          ? Colors.transparent
                          : (isSelected || isAnswerChecked
                                ? borderColor
                                : Colors.transparent),
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(iconData, color: iconColor, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          text,
                          style: TextStyle(
                            fontSize: 16,
                            // 정답 텍스트는 색상 강조
                            color:
                                isAnswerChecked &&
                                    problem.correctAnswer == choiceNumStr
                                ? const Color(0xFF2EBA9F)
                                : Colors.black87,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

          // 3. 주관식 입력창 (선지가 없을 경우 표시)
          if (problem.choices.isEmpty)
            TextField(
              enabled: !isAnswerChecked, // 채점 후 입력 불가
              onChanged: (val) => onAnswerSelected(problem.id, val),
              decoration: const InputDecoration(
                labelText: "정답 입력",
                border: OutlineInputBorder(),
              ),
            ),

          const SizedBox(height: 20),

          // 4. 해설 및 메모 영역 (채점 후에만 표시)
          if (isAnswerChecked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 정답 표시
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          "정답: ${problem.correctAnswer}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  // 메모가 있는 경우 표시
                  if (problem.memo != null && problem.memo!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Colors.grey),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.note_add,
                          size: 20,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "메모",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(problem.memo!, style: const TextStyle(fontSize: 14)),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
