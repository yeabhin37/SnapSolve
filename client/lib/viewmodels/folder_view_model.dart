import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/folder_model.dart';

class FolderViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Folder> _folders = [];
  List<Folder> get folders => _folders;

  int _wrongNoteCount = 0;
  int get wrongNoteCount => _wrongNoteCount;
  int _accuracy = 0;
  int get accuracy => _accuracy;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 폴더 목록 가져오기
  Future<void> loadFolders(String username) async {
    _isLoading = true;
    notifyListeners(); // 로딩 시작 알림

    final result = await _api.getFolders(username);

    _folders = result['folders'];
    _wrongNoteCount = result['wrongCount'];
    _accuracy = result['accuracy'];

    _isLoading = false;
    notifyListeners(); // 로딩 끝, 화면 갱신
  }

  // 폴더 추가하기
  Future<bool> addFolder(
    String username,
    String folderName,
    String color,
  ) async {
    if (folderName.isEmpty) return false;

    final success = await _api.createFolder(username, folderName, color);
    if (success) {
      await loadFolders(username); // 성공하면 목록 새로고침
    }
    return success;
  }

  Future<bool> editFolder(
    String username,
    int folderId,
    String name,
    String color,
  ) async {
    final success = await _api.updateFolder(username, folderId, name, color);
    if (success) await loadFolders(username);
    return success;
  }

  Future<bool> removeFolder(String username, int folderId) async {
    final success = await _api.deleteFolder(username, folderId);
    if (success) await loadFolders(username);
    return success;
  }
}
