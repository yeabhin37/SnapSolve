import 'dart:io';
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
  final TextEditingController _answerController = TextEditingController();
  final TextEditingController _memoController =
      TextEditingController(); // 메모 기능 추가 (UI 반영)

  String? _selectedFolder; // 저장할 폴더

  @override
  void initState() {
    super.initState();
    // 폴더 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final username = context.read<UserViewModel>().username;
      context.read<FolderViewModel>().loadFolders(username);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ocrVM = context.watch<OcrViewModel>();
    final userVM = context.read<UserViewModel>();
    final folderVM = context.watch<FolderViewModel>();

    // ---------------------------------------------------------
    // 1. 에러 발생 시 화면
    // ---------------------------------------------------------
    if (ocrVM.errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("오류 발생")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 60, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  "오류가 발생했습니다",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(ocrVM.errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => ocrVM.clear(),
                  child: const Text("다시 시도"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ---------------------------------------------------------
    // 2. 로딩 중 화면 (분석 중)
    // ---------------------------------------------------------
    if (ocrVM.isUploading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF1E2B58)),
              SizedBox(height: 20),
              Text(
                "문제를 분석하고 있습니다...",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // ---------------------------------------------------------
    // 3. 촬영 전 (카메라/갤러리 선택) - 디자인 프로토타입 3번째 장 스타일
    // ---------------------------------------------------------
    if (ocrVM.ocrResult == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade600, // 배경 어둡게 처리 (모달 느낌)
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            const Spacer(),
            const Text(
              "문제집 스캔하기",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 40),
            // 하단 흰색 영역
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2B58), // 네이비
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => ocrVM.pickAndScanImage(
                        userVM.username,
                        ImageSource.camera,
                      ),
                      child: const Text(
                        "카메라로 스캔",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEBEFF5), // 연한 회색
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => ocrVM.pickAndScanImage(
                        userVM.username,
                        ImageSource.gallery,
                      ),
                      child: const Text(
                        "갤러리에서 선택",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // ---------------------------------------------------------
    // 4. 결과 확인 및 수정 화면 (Form) - 디자인 프로토타입 4번째 장 스타일
    // ---------------------------------------------------------

    // 초기값 세팅
    if (_problemController.text.isEmpty) {
      _problemController.text = ocrVM.ocrResult!['problem'] ?? "";
    }
    // 폴더 자동 선택
    if (_selectedFolder == null && folderVM.folders.isNotEmpty) {
      _selectedFolder = folderVM.folders[0];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("문제집 스캔하기"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => ocrVM.clear(),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 타이틀
                  const Text(
                    "문제 정보 입력하기",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2B58),
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "스캔한 문제의 세부 정보를 입력하세요.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // 1. 문제 이름 (텍스트)
                  _buildGrayInputContainer(
                    child: TextField(
                      controller: _problemController,
                      maxLines: 4, // 여러 줄 입력 가능
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "문제 이름",
                        labelText: "문제 이름",
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // (참고용) 인식된 선지가 있다면 표시
                  if (ocrVM.ocrResult!['choices'] != null &&
                      (ocrVM.ocrResult!['choices'] as List).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "인식된 선지:",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 5),
                            ...List<String>.from(
                              ocrVM.ocrResult!['choices'],
                            ).map(
                              (c) => Text(
                                "• $c",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 2. 문제 정답
                  _buildGrayInputContainer(
                    child: TextField(
                      controller: _answerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "예: 3",
                        labelText: "문제 정답",
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 3. 저장 폴더 (드롭다운)
                  _buildGrayInputContainer(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: "저장 폴더",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: EdgeInsets.zero,
                        ),
                        value: _selectedFolder,
                        isExpanded: true,
                        items: folderVM.folders.map((folder) {
                          return DropdownMenuItem(
                            value: folder,
                            child: Text(folder),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedFolder = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // 4. 메모
                  _buildGrayInputContainer(
                    height: 120,
                    child: TextField(
                      controller: _memoController,
                      maxLines: null,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "메모를 입력하세요",
                        labelText: "메모",
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 버튼 영역
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // 수정하기 버튼 (회색)
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEBEFF5),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        // 사실 지금 화면이 수정 화면이므로, 키보드를 내리거나 하는 동작
                        FocusScope.of(context).unfocus();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("내용을 수정해주세요.")),
                        );
                      },
                      child: const Text(
                        "수정하기",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // 저장하기 버튼 (네이비)
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E2B58),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (_selectedFolder == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("폴더를 선택해주세요")),
                          );
                          return;
                        }
                        if (_answerController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("정답을 입력해주세요")),
                          );
                          return;
                        }

                        // 저장 로직 호출
                        final success = await ocrVM.saveProblem(
                          userVM.username,
                          _selectedFolder!,
                          _answerController.text,
                          _problemController.text,
                          [],
                        );

                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("저장 완료!")),
                          );
                          Navigator.pop(context); // 탭 화면으로 복귀
                        }
                      },
                      child: const Text(
                        "저장하기",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 회색 배경의 입력 컨테이너 헬퍼
  Widget _buildGrayInputContainer({required Widget child, double? height}) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEFF5), // 연한 회색 배경
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: child),
    );
  }
}
