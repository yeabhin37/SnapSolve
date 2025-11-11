// SnapSolve/client/bin/client.dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

final serverUrl = 'http://127.0.0.1:8000';

Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    printUsage();
    return;
  }

  final command = arguments[0];
  final args = arguments.sublist(1);

  switch (command) {
    case 'register':
      if (args.length < 1) return print('사용법: register <사용자이름>');
      await postToServer('/register', {'username': args[0]});
      break;
    case 'add-folder':
      if (args.length < 2) return print('사용법: add-folder <사용자이름> <폴더명>');
      await postToServer('/create-folder', {
        'username': args[0],
        'folder_name': args[1],
      });
      break;
    case 'ocr':
      if (args.length < 2) return print('사용법: ocr <사용자이름> <이미지경로>');
      await handleOcr(args[0], args[1]);
      break;
    case 'save':
      if (args.length < 4) return print('사용법: save <사용자이름> <임시ID> <폴더명> <정답>');
      await postToServer('/save', {
        'username': args[0],
        'temp_id': args[1],
        'folder_name': args[2],
        'correct_answer': args[3],
      });
      break;
    case 'folders':
      if (args.length < 1) return print('사용법: folders <사용자이름>');
      await postToServer('/folders', {'username': args[0]});
      break;
    case 'problems':
      if (args.length < 2) return print('사용법: problems <사용자이름> <폴더명>');
      await postToServer('/problems', {
        'username': args[0],
        'folder_name': args[1],
      });
      break;
    case 'solve':
      // 인자 개수 확인을 3개로 변경
      if (args.length < 3) return print('사용법: solve <사용자이름> <문제ID> <제출할답>');
      // 요청 본문에 username 추가
      await postToServer('/solve', {
        'username': args[0],
        'problem_id': args[1],
        'user_answer': args[2],
      });
      break;
    default:
      print('알 수 없는 명령어입니다: $command');
      printUsage();
  }
}

Future<void> handleOcr(String username, String imagePath) async {
  final file = File(imagePath);
  if (!await file.exists()) {
    print('오류: 파일을 찾을 수 없습니다: $imagePath');
    return;
  }
  final base64Image = base64Encode(await file.readAsBytes());
  final dataUri = 'data:image/jpeg;base64,$base64Image';

  await postToServer('/ocr', {'username': username, 'image_data': dataUri});
}

Future<void> postToServer(String path, Map<String, dynamic> body) async {
  final url = Uri.parse('$serverUrl$path');
  final headers = {'Content-Type': 'application/json'};
  print('\n[요청] $path');
  try {
    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
    handleResponse(response);
  } catch (e) {
    print('--- 통신 오류 ---');
    print('서버에 연결할 수 없습니다. 서버가 켜져 있는지 확인해주세요.');
    print('오류 상세: $e');
    print('------------------');
  }
}

void handleResponse(http.Response response) {
  print('--- 서버 응답 ---');
  if (response.statusCode >= 200 && response.statusCode < 300) {
    final responseBody = jsonDecode(utf8.decode(response.bodyBytes));

    // 'problems' 키가 있는지 확인하여 문제 목록 출력을 위한 특별 처리
    if (responseBody is Map && responseBody.containsKey('problems')) {
      printProblems(responseBody['problems']);
    } else {
      // 그 외의 응답은 기존처럼 예쁘게 JSON 형식으로 출력
      final prettyJson = JsonEncoder.withIndent('  ').convert(responseBody);
      print(prettyJson);
    }
  } else {
    print('오류가 발생했습니다 (코드: ${response.statusCode})');
    print('오류 내용: ${utf8.decode(response.bodyBytes)}');
  }
  print('------------------');
}

// 문제 목록을 보기 좋게 출력하기 위한 함수 추가
void printProblems(Map<String, dynamic> problems) {
  if (problems.isEmpty) {
    print('폴더에 저장된 문제가 없습니다.');
    return;
  }

  problems.forEach((id, data) {
    print('\n[문제 ID: $id]');
    print('Q. ${data['problem']}');
    if (data['choices'] != null && data['choices'].isNotEmpty) {
      for (var choice in data['choices']) {
        print('   $choice');
      }
    }
  });
}

void printUsage() {
  print('''
==================================================
  SnapSolve (CLI Version)
==================================================
사용법: dart run . <명령어> [옵션]
명령어:
  register <사용자이름>
  add-folder <사용자이름> <폴더명>
  ocr <사용자이름> <이미지 경로>
  save <사용자이름> <임시ID> <폴더명> <정답(숫자)>
  folders <사용자이름>
  problems <사용자이름> <폴더명>
  solve <사용자이름> <문제ID> <제출할 답(숫자)>
''');
}
