import 'package:flutter/material.dart';
import '../models/problem_model.dart';
import '../services/api_service.dart';

class SolveViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Problem> _problems = [];
  List<Problem> get problems => _problems;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 1. 특정 폴더의 문제 불러오기 (일반 풀이 모드)
  Future<void> loadProblems(int folderId) async {
    _isLoading = true;
    notifyListeners();

    _problems = await _api.getProblems(folderId);

    _isLoading = false;
    notifyListeners();
  }

  // 2. 오답노트 문제 불러오기 (전체 폴더 대상)
  Future<void> loadWrongNoteProblems(String username) async {
    _isLoading = true;
    notifyListeners();
    _problems = await _api.getWrongNoteProblems(username);
    _isLoading = false;
    notifyListeners();
  }

  // 3. 오답노트 상태 변경 (별표 토글)
  Future<void> updateWrongNote(List<String> ids, bool status) async {
    // 3-1. 서버 요청
    await _api.updateWrongNoteStatus(ids, status);

    // 3-2. 로컬 상태 즉시 반영 (UI 갱신을 위해 다시 로딩하지 않고 값만 변경)
    for (var p in _problems) {
      if (ids.contains(p.id)) {
        p.isWrongNote = status;
      }
    }
    notifyListeners();
  }

  // 4. 정답 체크 로직 (UI에서 호출)
  bool checkAnswer(Problem problem, String userAnswer) {
    // 공백 제거 후 비교
    return problem.correctAnswer?.trim() == userAnswer.trim();
  }
}
