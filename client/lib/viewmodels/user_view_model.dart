import 'package:flutter/material.dart';
import '../services/api_service.dart';

class UserViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();

  String _username = '';
  String get username => _username;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> login(String name) async {
    _isLoading = true;
    notifyListeners();

    final success = await _api.register(name);
    if (success) {
      _username = name; // 로그인 성공 시 이름 저장
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
