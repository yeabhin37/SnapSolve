import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/user_view_model.dart';
import '../../viewmodels/solve_view_model.dart';
import '../../viewmodels/ocr_view_model.dart';
import '../../models/problem_model.dart';
import '../camera/ocr_preview_screen.dart';

class SolveScreen extends StatefulWidget {
  final String folderName;

  const SolveScreen({super.key, required this.folderName});

  @override
  State<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends State<SolveScreen> {
  final PageController _pageController = PageController();

  // 상태 관리 변수들
  int _currentProblemIndex = 0;
  bool _isFinished = false; // 모든 문제 풀이 완료 여부

  // 사용자가 입력한 답 (문제ID : 입력값)
  final Map<String, String> _userAnswers = {};
  // 채점 결과 (문제ID : 정답여부)
  final Map<String, bool> _results = {};
  // 현재 문제의 정답 확인 여부 (UI 변경용)
  bool _isCurrentAnswerChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final username = context.read<UserViewModel>().username;
      context.read<SolveViewModel>().loadProblems(username, widget.folderName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final solveVM = context.watch<SolveViewModel>();
    final totalProblems = solveVM.problems.length;
    final isEmpty = !solveVM.isLoading && solveVM.problems.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName), // 폴더명 (예: ADP 필기)
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: solveVM.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1E2B58)),
            )
          : isEmpty
          ? _buildEmptyView()
          : _isFinished
          ? _buildScoreView(solveVM.problems) // 결과 화면
          : Column(
              children: [
                // 1. 상단 진행 바 (Progress Bar)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${_currentProblemIndex + 1}/$totalProblems",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (_currentProblemIndex + 1) / totalProblems,
                        backgroundColor: const Color(0xFFEBEFF5),
                        color: const Color(0xFF1E2B58), // 네이비
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),

                // 2. 문제 영역 (PageView)
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics:
                        const NeverScrollableScrollPhysics(), // 버튼으로만 이동 가능
                    itemCount: totalProblems,
                    onPageChanged: (index) {
                      setState(() {
                        _currentProblemIndex = index;
                        _isCurrentAnswerChecked = false; // 페이지 넘기면 정답 확인 상태 초기화
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildProblemPage(solveVM.problems[index]);
                    },
                  ),
                ),
              ],
            ),

      // 3. 하단 버튼 (정답 확인 / 다음 문제) - 결과 화면일 때는 숨김
      bottomNavigationBar: (_isFinished || solveVM.isLoading || isEmpty)
          ? null
          : _buildBottomButton(solveVM),

      // 4. 빈 화면일 때만 카메라 플로팅 버튼 표시 (디자인 우측 하단 버튼)
      floatingActionButton: isEmpty
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF1E2B58),
              shape: const CircleBorder(),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white),
              onPressed: () => _showScanBottomSheet(context),
            )
          : null,
    );
  }

  void _showScanBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // 뒤에 둥근 모서리 보이게 투명 처리
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 내용물 크기만큼만 높이 차지
            children: [
              // 상단 핸들 (회색 바)
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // 타이틀
              const Text(
                "문제집 스캔하기",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2B58),
                ),
              ),
              const SizedBox(height: 30),

              // 1. 카메라로 스캔 버튼
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2B58), // 네이비
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // 시트 닫기
                    _processScan(ImageSource.camera); // 촬영 시작
                  },
                  child: const Text(
                    "카메라로 스캔",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // 2. 갤러리에서 선택 버튼
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEBEFF5), // 연한 회색/보라
                    foregroundColor: Colors.black87, // 글자색 검정
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context); // 시트 닫기
                    _processScan(ImageSource.gallery); // 갤러리 열기
                  },
                  child: const Text(
                    "갤러리에서 선택",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _processScan(ImageSource source) {
    final userVM = context.read<UserViewModel>();
    final ocrVM = context.read<OcrViewModel>();

    // 1. 이미지 피킹 및 OCR 요청 시작
    ocrVM.pickAndScanImage(userVM.username, source);

    // 2. 결과 확인 화면으로 이동 (로딩 상태를 보여줌)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OcrPreviewScreen()),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.find_in_page_outlined,
              size: 50,
              color: Color(0xFF1E2B58),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "저장된 문제가 없습니다",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2B58),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "새로운 문제를 스캔하여 나만의 학습지를 만들어보세요.",
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildProblemPage(Problem problem) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 문제 텍스트 박스 (회색 배경)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(0xFFEBEFF5), // 연한 회색
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

          // 선지 목록
          if (problem.choices.isNotEmpty)
            ...problem.choices.asMap().entries.map((entry) {
              final idx = entry.key + 1; // 1, 2, 3...
              final text = entry.value;

              // 선택 상태 확인
              final isSelected = _userAnswers[problem.id] == idx.toString();

              // 정답 체크 후 스타일링
              Color borderColor = Colors.transparent;
              Color bgColor = Colors.transparent;
              Color iconColor = Colors.grey.shade300;
              IconData iconData = Icons.check_box_outline_blank;

              if (_isCurrentAnswerChecked) {
                // 정답 확인 모드
                final isAnswer = problem.correctAnswer == idx.toString();
                if (isAnswer) {
                  // 실제 정답인 선지 (초록색 강조)
                  borderColor = const Color(0xFF2EBA9F);
                  bgColor = const Color(0xFF2EBA9F).withOpacity(0.1);
                  iconColor = const Color(0xFF2EBA9F);
                  iconData = Icons.check_box;
                } else if (isSelected && !isAnswer) {
                  // 내가 찍었는데 틀린 선지 (빨간색)
                  borderColor = Colors.red.shade300;
                  bgColor = Colors.red.withOpacity(0.05);
                  iconColor = Colors.red;
                  iconData = Icons.close; // x 표시
                }
              } else {
                // 풀이 중 모드
                if (isSelected) {
                  borderColor = const Color(0xFF2EBA9F); // 민트
                  bgColor = const Color(0xFF2EBA9F).withOpacity(0.05);
                  iconColor = const Color(0xFF2EBA9F);
                  iconData = Icons.check_box;
                }
              }

              return GestureDetector(
                onTap: _isCurrentAnswerChecked
                    ? null
                    : () {
                        setState(() {
                          _userAnswers[problem.id] = idx.toString();
                        });
                      },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(
                      color:
                          _isCurrentAnswerChecked &&
                              borderColor == Colors.transparent
                          ? Colors.transparent
                          : (isSelected || _isCurrentAnswerChecked
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
                            color:
                                _isCurrentAnswerChecked &&
                                    problem.correctAnswer == idx.toString()
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

          // 만약 주관식이라면 (선지 없음)
          if (problem.choices.isEmpty)
            TextField(
              enabled: !_isCurrentAnswerChecked,
              onChanged: (val) {
                _userAnswers[problem.id] = val;
              },
              decoration: const InputDecoration(
                labelText: "정답 입력",
                border: OutlineInputBorder(),
              ),
            ),

          const SizedBox(height: 20),

          // 정답 해설 (체크 후에만 보임)
          if (_isCurrentAnswerChecked)
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20, color: Colors.grey),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "정답: ${problem.correctAnswer}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(SolveViewModel solveVM) {
    final currentProblem = solveVM.problems[_currentProblemIndex];
    final isLastPage = _currentProblemIndex == solveVM.problems.length - 1;

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          // 왼쪽: 정답 확인 버튼 (아직 확인 안 했을 때만)
          if (!_isCurrentAnswerChecked)
            Expanded(
              child: SizedBox(
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEBEFF5), // 회색
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    if (_userAnswers[currentProblem.id] == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("답을 선택해주세요!")),
                      );
                      return;
                    }
                    // 정답 체크 로직
                    final isCorrect = solveVM.checkAnswer(
                      currentProblem,
                      _userAnswers[currentProblem.id]!,
                    );
                    setState(() {
                      _results[currentProblem.id] = isCorrect;
                      _isCurrentAnswerChecked = true; // 화면 갱신 (색상 바뀜)
                    });
                  },
                  child: const Text(
                    "정답 확인",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

          if (!_isCurrentAnswerChecked) const SizedBox(width: 15),

          // 오른쪽: 다음 문제 / 결과 보기 버튼
          Expanded(
            child: SizedBox(
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2B58), // 네이비
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  if (!_isCurrentAnswerChecked) {
                    // 확인 안 하고 넘어가려 하면 경고 (선택사항)
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("먼저 정답을 확인해주세요.")),
                    );
                    return;
                  }

                  if (isLastPage) {
                    setState(() => _isFinished = true); // 결과 화면으로 전환
                  } else {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(
                  isLastPage ? "결과 보기" : "다음 문제",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreView(List<Problem> problems) {
    int correctCount = 0;
    _results.forEach((_, isCorrect) {
      if (isCorrect) correctCount++;
    });
    final score = (correctCount / problems.length * 100).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          const Text(
            "시험 결과",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2B58),
            ),
          ),
          const SizedBox(height: 30),

          // 점수 카드 영역
          Row(
            children: [
              // 점수
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "점수",
                        style: TextStyle(
                          color: Color(0xFF1E2B58),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$score/100",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              // 맞힌 문제 수
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "맞힌 문제 수",
                        style: TextStyle(
                          color: Color(0xFF1E2B58),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "$correctCount/${problems.length}",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // 기능 버튼들
          _buildActionButton(
            "틀린 문제 오답 노트에 저장",
            Colors.grey.shade200,
            Colors.black87,
          ),
          const SizedBox(height: 15),
          _buildActionButton(
            "나만의 문제은행에 추가",
            Colors.grey.shade200,
            Colors.black87,
          ),
          const SizedBox(height: 15),

          // 다시 풀기 (민트색 강조)
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2EBA9F), // 민트
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // 초기화 후 다시 시작
                setState(() {
                  _currentProblemIndex = 0;
                  _isFinished = false;
                  _userAnswers.clear();
                  _results.clear();
                  _isCurrentAnswerChecked = false;
                });
              },
              child: const Text(
                "다시 풀기",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 15),
          TextButton(
            onPressed: () => Navigator.pop(context), // 뒤로가기
            child: const Text("홈으로 돌아가기", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color bgColor, Color textColor) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {}, // 기능 미구현 (UI용)
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
