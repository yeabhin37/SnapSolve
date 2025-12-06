import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();

  // 로그인된 사용자 이름 (앱 전역에서 식별자로 사용)
  String _username = '';
  String get username => _username;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 로그인 처리
  Future<bool> login(String name, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await _api.login(name, password);
    if (success) {
      _username = name; // 로그인 성공 시 이름 저장
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // 회원가입 처리
  Future<bool> register(String name, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await _api.register(name, password);

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
