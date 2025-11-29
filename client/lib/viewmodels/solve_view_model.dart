import 'package:flutter/material.dart';
import '../models/problem_model.dart';
import '../services/api_service.dart';

class SolveViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Problem> _problems = [];
  List<Problem> get problems => _problems;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 문제 목록 불러오기
  Future<void> loadProblems(String username, String folderName) async {
    _isLoading = true;
    notifyListeners();

    _problems = await _api.getProblems(username, folderName);

    _isLoading = false;
    notifyListeners();
  }

  // 정답 체크 (UI에서 호출)
  bool checkAnswer(Problem problem, String userAnswer) {
    // 공백 제거 후 비교
    return problem.correctAnswer?.trim() == userAnswer.trim();
  }
}
