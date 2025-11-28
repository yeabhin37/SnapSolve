import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../services/api_service.dart';

class OcrViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  bool _isUploading = false;
  bool get isUploading => _isUploading;

  // 서버에서 받은 임시 데이터 (미리보기용)
  Map<String, dynamic>? _ocrResult;
  Map<String, dynamic>? get ocrResult => _ocrResult;

  String? _tempId; // 저장할 때 필요한 ID

  // 1. 이미지 선택 및 압축 후 OCR 요청
  Future<void> pickAndScanImage(String username, ImageSource source) async {
    try {
      // 1-1. 이미지 선택
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      _isUploading = true;
      notifyListeners();

      // 1-2. 이미지 압축 (서버 전송 속도 향상)
      File imageFile = File(pickedFile.path);
      // (선택사항: 압축 로직이 복잡하면 일단 원본 전송)

      // 1-3. 서버 전송
      final result = await _api.ocrImage(username, imageFile);

      _tempId = result['temp_id'];
      _ocrResult = result['preview']; // { "problem": "...", "choices": [...] }
    } catch (e) {
      print('OCR Error: $e');
      _ocrResult = null; // 실패 시 초기화
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // 2. 최종 저장
  Future<bool> saveProblem(
    String username,
    String folderName,
    String answer,
    String editedProblem,
    List<String> editedChoices,
  ) async {
    if (_tempId == null) return false;

    // (참고) 현재 서버 API는 텍스트 수정을 지원하지 않고, 원본 OCR 결과만 저장하는 구조입니다.
    // 하지만 일단 Client에서는 수정된 값을 가지고 있다고 가정하고,
    // 서버가 수정 기능을 지원하게 되면 update API를 호출하거나 save API를 고쳐야 합니다.
    // *일단 지금은 서버 스펙인 save(temp_id, correct_answer)만 호출합니다.*

    try {
      await _api.saveProblem(username, _tempId!, folderName, answer);

      // 저장 후 초기화
      _ocrResult = null;
      _tempId = null;
      notifyListeners();
      return true;
    } catch (e) {
      print('Save Error: $e');
      return false;
    }
  }

  // 화면 초기화 (뒤로가기 등)
  void clear() {
    _ocrResult = null;
    _tempId = null;
    notifyListeners();
  }
}
