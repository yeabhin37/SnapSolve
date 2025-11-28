import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../viewmodels/user_view_model.dart';
import '../../viewmodels/folder_view_model.dart';
import '../../viewmodels/ocr_view_model.dart';

class OcrPreviewScreen extends StatefulWidget {
  const OcrPreviewScreen({super.key});

  @override
  State<OcrPreviewScreen> createState() => _OcrPreviewScreenState();
}

class _OcrPreviewScreenState extends State<OcrPreviewScreen> {
  // 입력 폼 컨트롤러
  final TextEditingController _problemController = TextEditingController();
  final TextEditingController _answerController =
      TextEditingController(); // 정답(숫자)

  String? _selectedFolder; // 저장할 폴더 선택

  @override
  void initState() {
    super.initState();
    // 폴더 목록이 없을 수도 있으니 한 번 불러옴
    final username = context.read<UserViewModel>().username;
    context.read<FolderViewModel>().loadFolders(username);
  }

  @override
  Widget build(BuildContext context) {
    final ocrVM = context.watch<OcrViewModel>();
    final userVM = context.read<UserViewModel>();
    final folderVM = context.watch<FolderViewModel>();

    // 1. 로딩 중일 때
    if (ocrVM.isUploading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text("문제를 분석하고 있습니다..."),
            ],
          ),
        ),
      );
    }

    // 2. 결과가 없을 때 (촬영 전) -> 카메라/갤러리 선택 화면
    if (ocrVM.ocrResult == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("문제 촬영")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_enhance, size: 100, color: Colors.grey),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildScanButton(
                    icon: Icons.camera_alt,
                    label: "카메라",
                    onTap: () => ocrVM.pickAndScanImage(
                      userVM.username,
                      ImageSource.camera,
                    ),
                  ),
                  const SizedBox(width: 20),
                  _buildScanButton(
                    icon: Icons.photo_library,
                    label: "갤러리",
                    onTap: () => ocrVM.pickAndScanImage(
                      userVM.username,
                      ImageSource.gallery,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    // 3. 결과가 있을 때 -> 미리보기 및 저장 화면

    // 컨트롤러에 초기값 세팅 (한 번만)
    if (_problemController.text.isEmpty) {
      _problemController.text = ocrVM.ocrResult!['problem'] ?? "";
    }
    // 기본 폴더 선택 (첫 번째 폴더)
    if (_selectedFolder == null && folderVM.folders.isNotEmpty) {
      _selectedFolder = folderVM.folders[0];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("문제 확인 및 저장"),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            ocrVM.clear(); // 결과 초기화
            _problemController.clear();
            _answerController.clear();
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 문제 텍스트 미리보기 (수정 가능하게 TextField로)
            const Text("문제 내용", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _problemController,
              maxLines: 5,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),

            const SizedBox(height: 20),

            // 선지 목록 보여주기
            const Text("선지 목록", style: TextStyle(fontWeight: FontWeight.bold)),
            if (ocrVM.ocrResult!['choices'] != null)
              ...List<String>.from(ocrVM.ocrResult!['choices']).map(
                (choice) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text("• $choice"),
                ),
              ),

            const SizedBox(height: 20),
            const Divider(),

            // 저장 옵션
            const Text(
              "저장 설정",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 폴더 선택
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "저장할 폴더"),
              value: _selectedFolder,
              items: folderVM.folders.map((folder) {
                return DropdownMenuItem(value: folder, child: Text(folder));
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedFolder = val);
              },
            ),

            const SizedBox(height: 10),

            // 정답 입력
            TextField(
              controller: _answerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "정답 (번호 입력)",
                border: OutlineInputBorder(),
                hintText: "예: 3",
              ),
            ),

            const SizedBox(height: 30),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_selectedFolder == null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("폴더를 선택해주세요")));
                    return;
                  }
                  if (_answerController.text.isEmpty) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("정답을 입력해주세요")));
                    return;
                  }

                  final success = await ocrVM.saveProblem(
                    userVM.username,
                    _selectedFolder!,
                    _answerController.text,
                    _problemController.text,
                    [], // 선지 수정은 일단 패스
                  );

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("저장 완료!")));
                    Navigator.pop(context); // 홈 화면으로 복귀
                  }
                },
                child: const Text("문제 저장하기", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: const Color(0xFF1E3A8A)),
            const SizedBox(height: 5),
            Text(label),
          ],
        ),
      ),
    );
  }
}
