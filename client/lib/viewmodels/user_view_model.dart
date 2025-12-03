import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();

  String _username = '';
  String get username => _username;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 로그인
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

  // 회원가입
  Future<bool> register(String name, String password) async {
    _isLoading = true;
    notifyListeners();

    final success = await _api.register(name, password);

    // 회원가입 성공 시 바로 로그인 처리까지 할지, 아니면 다시 로그인하라고 할지는 기획에 따라 다름.
    // 여기서는 가입 성공만 리턴
    _isLoading = false;
    notifyListeners();
    return success;
  }
}
