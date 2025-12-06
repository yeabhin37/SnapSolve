import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class OcrViewModel extends ChangeNotifier {
  final ApiService _api = ApiService();
  final ImagePicker _picker = ImagePicker();

  // 이미지 업로드 및 분석 중인지 여부
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  // 서버에서 받은 OCR 분석 결과 (미리보기용 데이터)
  // 예: { "problem": "...", "choices": [...] }
  Map<String, dynamic>? _ocrResult;
  Map<String, dynamic>? get ocrResult => _ocrResult;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 저장 요청 시 필요한 임시 ID (OCR 요청 시 서버가 발급)
  String? _tempId;

  // 1. 이미지 선택(카메라/갤러리) 및 압축 후 OCR 요청
  Future<void> pickAndScanImage(String username, ImageSource source) async {
    try {
      _errorMessage = null;

      // 1-1. 이미지 선택
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      _isUploading = true;
      notifyListeners();

      // 1-2. 파일 객체 생성 및 서버 전송
      File imageFile = File(pickedFile.path);
      final result = await _api.ocrImage(username, imageFile);

      // 1-3. 결과 수신
      _tempId = result['temp_id'];
      _ocrResult = result['preview']; // { "problem": "...", "choices": [...] }
    } catch (e) {
      _errorMessage = '이미지 분석 중 오류가 발생했습니다.';
      _ocrResult = null; // 실패 시 초기화
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  // 2. 최종 문제 저장
  Future<bool> saveProblem(
    String username,
    int folderId,
    String answer,
    String editedProblem,
    List<String> editedChoices,
    String? memo,
  ) async {
    if (_tempId == null) return false;

    try {
      // 사용자가 수정한 내용과 함께 저장 요청
      await _api.saveProblem(
        username,
        _tempId!,
        folderId,
        answer,
        editedProblem,
        editedChoices,
        memo,
      );

      // 저장 성공 시 상태 초기화
      _ocrResult = null;
      _tempId = null;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // 화면을 나갈 때 등 상태 초기화
  void clear() {
    _ocrResult = null;
    _tempId = null;
    notifyListeners();
  }
}
