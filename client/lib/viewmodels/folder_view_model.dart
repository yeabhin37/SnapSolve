import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FolderViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<String> _folders = [];
  List<String> get folders => _folders;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 폴더 목록 가져오기
  Future<void> loadFolders(String username) async {
    _isLoading = true;
    notifyListeners(); // 로딩 시작 알림

    _folders = await _api.getFolders(username);

    _isLoading = false;
    notifyListeners(); // 로딩 끝, 화면 갱신
  }

  // 폴더 추가하기
  Future<bool> addFolder(String username, String folderName) async {
    if (folderName.isEmpty) return false;

    final success = await _api.createFolder(username, folderName);
    if (success) {
      await loadFolders(username); // 성공하면 목록 새로고침
    }
    return success;
  }
}
