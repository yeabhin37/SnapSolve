import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/problem_model.dart';
import '../models/folder_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // ------ 1. 인증 (Auth) ------
  // 1-1. 회원가입
  Future<bool> register(String username, String password) async {
    final url = Uri.parse('${Constants.baseUrl}/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );
      // 201 Created 응답이 오면 성공
      return response.statusCode == 201;
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

  // ------ 2. 사용자 통계 (User Stats) ------
  // 학습률 통계 업데이트
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

  // ------ 3. 폴더 관리 (Folders) ------
  // 3-1. 폴더 목록 및 전체 통계 조회
  Future<Map<String, dynamic>> getFolders(String username) async {
    final url = Uri.parse('${Constants.baseUrl}/folders?username=$username');
    try {
      final response = await http.get(url); // GET 방식

      if (response.statusCode == 200) {
        // 한글 깨짐 방지를 위해 utf8.decode 사용
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
    // 실패 시 빈 데이터 반환
    return {'folders': <Folder>[], 'wrongCount': 0, 'accuracy': 0};
  }

  // 3-2. 폴더 생성
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

  // 3-3. 폴더 수정
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

  // 3-4. 폴더 삭제
  Future<bool> deleteFolder(String username, int folderId) async {
    final url = Uri.parse(
      '${Constants.baseUrl}/folders/$folderId?username=$username',
    );
    try {
      final response = await http.delete(url);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      return false;
    }
  }

  // ------ 4. 문제 관리 & OCR (Problems) ------
  // 4-1. 이미지 OCR 요청 (이미지 -> 텍스트 추출 미리보기)
  Future<Map<String, dynamic>> ocrImage(String username, File imageFile) async {
    final url = Uri.parse('${Constants.baseUrl}/ocr');
    // 파일을 바이트로 읽은 후 Base64 문자열로 인코딩하여 전송
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

  // 4-2. 문제 최종 저장 (OCR 결과 또는 수정된 내용 저장)
  Future<void> saveProblem(
    String username,
    String tempId, // OCR 요청 시 받은 임시 ID
    int folderId,
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
        'folder_id': folderId,
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

  // 4-3. 폴더의 문제 목록 조회
  Future<List<Problem>> getProblems(int folderId) async {
    final url = Uri.parse('${Constants.baseUrl}/problems?folder_id=$folderId');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final Map<String, dynamic> problemsMap = data['problems'];

        List<Problem> problemList = [];
        // Map 형태인 응답을 List<Problem>으로 변환
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

  // 4-4. 오답노트 문제 목록 조회
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

  // 4-5. 오답노트 상태 변경 (별표 추가/제거)
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

  // ------ 5. 시험 이력 (History) ------
  // 5-1. 점수 기록 저장
  Future<void> saveExamScore(String username, int score) async {
    print("👉 점수 저장 시도: $username, $score점");
    final url = Uri.parse('${Constants.baseUrl}/history');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'score': score}),
      );
      print("👉 서버 응답 코드: ${response.statusCode}");
      print("👉 서버 응답 내용: ${utf8.decode(response.bodyBytes)}");
    } catch (e) {
      print('점수 저장 실패: $e');
    }
  }

  // 5-2. 점수 기록 가져오기
  Future<List<Map<String, dynamic>>> getExamHistory(String username) async {
    final url = Uri.parse('${Constants.baseUrl}/history?username=$username');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        // 서버 응답: { "data": [ {"date": "...", "score": ...}, ... ] }
        final list = List<Map<String, dynamic>>.from(data['data']);
        return list;
      }
    } catch (e) {
      print('히스토리 조회 실패: $e');
    }
    return [];
  }
}
