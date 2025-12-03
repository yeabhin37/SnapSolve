import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/problem_model.dart';
import '../models/folder_model.dart';

class ApiService {
  // 싱글톤 패턴 (어디서든 ApiService()로 불러다 쓰기 위함)
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // 1-1. 회원가입
  Future<bool> register(String username, String password) async {
    final url = Uri.parse('${Constants.baseUrl}/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        // 백엔드 스키마에 맞춰 password 필드 추가 (더미 값)
        body: jsonEncode({'username': username, 'password': password}),
      );
      // 200(성공)이면 로그인 성공으로 처리
      return response.statusCode == 200;
    } catch (e) {
      print('회원가입 오류: $e');
      return false;
    }
  }

  // 1-2. 로그인
  Future<bool> login(String username, String password) async {
    final url = Uri.parse('${Constants.baseUrl}/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('로그인 오류: $e');
      return false;
    }
  }

  // 2. 폴더 목록 가져오기
  Future<List<Folder>> getFolders(String username) async {
    final url = Uri.parse('${Constants.baseUrl}/folders');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final list = data['folders'] as List;
        return list.map((e) => Folder.fromJson(e)).toList();
      }
    } catch (e) {
      print('폴더 조회 오류: $e');
    }
    return [];
  }

  // 3. 폴더 생성
  Future<bool> createFolder(String username, String folderName) async {
    final url = Uri.parse('${Constants.baseUrl}/create-folder');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'folder_name': folderName}),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('폴더 생성 오류: $e');
      return false;
    }
  }

  // 4. 이미지 OCR 요청
  Future<Map<String, dynamic>> ocrImage(String username, File imageFile) async {
    final url = Uri.parse('${Constants.baseUrl}/ocr');

    // 파일을 읽어서 Base64로 변환
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);
    final dataUri = 'data:image/jpeg;base64,$base64Image';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'image_data': dataUri}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      throw Exception('OCR 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  // 5. 문제 최종 저장
  Future<void> saveProblem(
    String username,
    String tempId,
    String folderName,
    String answer,
    String? editedProblemText,
  ) async {
    final url = Uri.parse('${Constants.baseUrl}/save');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'temp_id': tempId,
        'folder_name': folderName,
        'correct_answer': answer,
        'problem_text': editedProblemText,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('저장 실패: ${utf8.decode(response.bodyBytes)}');
    }
  }

  // 6. 특정 폴더의 문제 목록 가져오기
  Future<List<Problem>> getProblems(String username, String folderName) async {
    final url = Uri.parse('${Constants.baseUrl}/problems');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'folder_name': folderName}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final Map<String, dynamic> problemsMap = data['problems'];

        // 맵 형태의 응답을 리스트로 변환
        List<Problem> problemList = [];
        problemsMap.forEach((key, value) {
          // id는 키값, 나머지는 value에 있음
          final problemData = value as Map<String, dynamic>;
          problemData['id'] = key; // 모델 생성을 위해 id 주입
          problemList.add(Problem.fromJson(problemData));
        });
        return problemList;
      }
    } catch (e) {
      print('문제 목록 조회 오류: $e');
    }
    return [];
  }
}
