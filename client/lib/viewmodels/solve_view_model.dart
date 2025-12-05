import 'package:flutter/material.dart';
import '../models/problem_model.dart';
import '../services/api_service.dart';

class SolveViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Problem> _problems = [];
  List<Problem> get problems => _problems;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 일반 문제 불러오기
  Future<void> loadProblems(int folderId) async {
    _isLoading = true;
    notifyListeners();

    _problems = await _api.getProblems(folderId);

    _isLoading = false;
    notifyListeners();
  }

  // 오답노트 문제 로딩
  Future<void> loadWrongNoteProblems(String username) async {
    _isLoading = true;
    notifyListeners();
    _problems = await _api.getWrongNoteProblems(username);
    _isLoading = false;
    notifyListeners();
  }

  // 상태 변경 요청 (별표, 저장 등)
  Future<void> updateWrongNote(List<String> ids, bool status) async {
    // 1. 서버 요청
    await _api.updateWrongNoteStatus(ids, status);

    // 2. 로컬 상태 업데이트 (화면 즉시 반영을 위해)
    for (var p in _problems) {
      if (ids.contains(p.id)) {
        p.isWrongNote = status;
      }
    }
    notifyListeners();
  }

  // 정답 체크 (UI에서 호출)
  bool checkAnswer(Problem problem, String userAnswer) {
    // 공백 제거 후 비교
    return problem.correctAnswer?.trim() == userAnswer.trim();
  }
}
