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
      return response.statusCode == 201; // created
    } catch (e) {
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
      return false;
    }
  }

  // 1-3. 학습률 통계 업데이트
  Future<void> updateUserStats(
    String username,
    int solvedCount,
    int correctCount,
  ) async {
    final url = Uri.parse('${Constants.baseUrl}/user/stats');
    try {
      await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'solved_count': solvedCount,
          'correct_count': correctCount,
        }),
      );
    } catch (e) {
      print('통계 업데이트 오류: $e');
    }
  }

  // 2. 폴더 목록 조회
  Future<Map<String, dynamic>> getFolders(String username) async {
    final url = Uri.parse('${Constants.baseUrl}/folders?username=$username');
    try {
      final response = await http.get(url); // GET 방식

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final list = data['folders'] as List;
        final folders = list.map((e) => Folder.fromJson(e)).toList();
        final wrongCount = data['wrong_note_count'] ?? 0;
        final accuracy = data['accuracy'] ?? 0;

        return {
          'folders': folders,
          'wrongCount': wrongCount,
          'accuracy': accuracy,
        };
      }
    } catch (e) {
      print('폴더 조회 오류: $e');
    }
    return {'folders': <Folder>[], 'wrongCount': 0, 'accuracy': 0};
  }

  // 3. 폴더 생성
  Future<bool> createFolder(
    String username,
    String folderName,
    String colorCode,
  ) async {
    final url = Uri.parse('${Constants.baseUrl}/folders');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'folder_name': folderName,
          'color': colorCode,
        }),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // 4. 폴더 수정
  Future<bool> updateFolder(
    String username,
    int folderId,
    String newName,
    String newColor,
  ) async {
    final url = Uri.parse('${Constants.baseUrl}/folders/$folderId');
    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username, // 권한 확인용
          'new_name': newName,
          'new_color': newColor,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 5. 폴더 삭제
  Future<bool> deleteFolder(String username, int folderId) async {
    // username을 쿼리로 보내거나 헤더로 보내야 함 (여기선 쿼리로)
    final url = Uri.parse(
      '${Constants.baseUrl}/folders/$folderId?username=$username',
    );
    try {
      final response = await http.delete(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 6. OCR
  Future<Map<String, dynamic>> ocrImage(String username, File imageFile) async {
    final url = Uri.parse('${Constants.baseUrl}/ocr');
    final bytes = await imageFile.readAsBytes(); // 파일을 읽어서 Base64로 변환
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

  // 7. 문제 저장
  Future<void> saveProblem(
    String username,
    String tempId,
    int folderId, // [변경] int 타입 ID
    String answer,
    String? editedProblemText,
    List<String>? editedChoices,
    String? memo,
  ) async {
    final url = Uri.parse('${Constants.baseUrl}/problems');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'temp_id': tempId,
        'folder_id': folderId, // ID 전송
        'correct_answer': answer,
        'problem_text': editedProblemText,
        'choices': editedChoices,
        'memo': memo,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('저장 실패');
    }
  }

  // 8. 폴더의 문제 목록 조회
  Future<List<Problem>> getProblems(int folderId) async {
    final url = Uri.parse('${Constants.baseUrl}/problems?folder_id=$folderId');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final Map<String, dynamic> problemsMap = data['problems'];
        List<Problem> problemList = [];
        problemsMap.forEach((key, value) {
          final problemData = value as Map<String, dynamic>;
          problemData['id'] = key;
          problemList.add(Problem.fromJson(problemData));
        });
        return problemList;
      }
    } catch (e) {
      print('문제 목록 조회 오류: $e');
    }
    return [];
  }

  // 9. 오답노트 문제 목록 조회
  Future<List<Problem>> getWrongNoteProblems(String username) async {
    final url = Uri.parse(
      '${Constants.baseUrl}/wrong-notes?username=$username',
    );
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final Map<String, dynamic> problemsMap = data['problems'];
        List<Problem> problemList = [];
        problemsMap.forEach((key, value) {
          final problemData = value as Map<String, dynamic>;
          problemData['id'] = key;
          problemList.add(Problem.fromJson(problemData));
        });
        return problemList;
      }
    } catch (e) {
      print('오답노트 조회 오류: $e');
    }
    return [];
  }

  // 오답노트 상태 변경 (별표, 저장 등)
  Future<bool> updateWrongNoteStatus(
    List<String> problemIds,
    bool isWrongNote,
  ) async {
    final url = Uri.parse('${Constants.baseUrl}/problems/wrong-note');
    try {
      final response = await http.patch(
        // PATCH 방식
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'problem_ids': problemIds,
          'is_wrong_note': isWrongNote,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
