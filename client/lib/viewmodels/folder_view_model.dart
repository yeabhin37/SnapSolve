import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/folder_model.dart';

class FolderViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();

  // 폴더 리스트 상태
  List<Folder> _folders = [];
  List<Folder> get folders => _folders;

  // 통계 상태
  int _wrongNoteCount = 0;
  int get wrongNoteCount => _wrongNoteCount;
  int _accuracy = 0;
  int get accuracy => _accuracy;

  // 로딩 상태
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // 1. 폴더 목록 및 통계 정보 가져오기
  Future<void> loadFolders(String username) async {
    _isLoading = true;
    notifyListeners(); // 로딩 시작 알림

    final result = await _api.getFolders(username);

    // 결과 업데이트
    _folders = result['folders'];
    _wrongNoteCount = result['wrongCount'];
    _accuracy = result['accuracy'];

    _isLoading = false;
    notifyListeners(); // 로딩 종료 및 데이터 UI 반영
  }

  // 2. 폴더 추가하기
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

  // 3. 폴더 수정
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

  // 4. 폴더 삭제
  Future<bool> removeFolder(String username, int folderId) async {
    final success = await _api.deleteFolder(username, folderId);
    if (success) await loadFolders(username);
    return success;
  }
}
