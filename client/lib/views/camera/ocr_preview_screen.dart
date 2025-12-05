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
  final TextEditingController _memoController = TextEditingController();
  final List<Color> _folderColors = const [
    Color(0xFF1E2B58), // 네이비
    Color(0xFF2EBA9F), // 민트
    Color(0xFFE57373), // 코랄
    Color(0xFF64B5F6), // 블루
    Color(0xFFFBC02D), // 옐로우
    Color(0xFF546E7A), // 그레이
  ];

  // 선지들을 관리할 컨트롤러 리스트
  List<TextEditingController> _choiceControllers = [];

  // 데이터가 초기화되었는지 확인하는 플래그
  bool _isDataLoaded = false;
  int? _selectedFolderId;

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
  void dispose() {
    _problemController.dispose();
    _answerController.dispose();
    _memoController.dispose();
    // 선지 컨트롤러들도 해제
    for (var controller in _choiceControllers) {
      controller.dispose();
    }
    super.dispose();
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
      _isDataLoaded = false; // 에러 나면 데이터 로드 상태 초기화
      return Scaffold(
        appBar: AppBar(title: const Text("오류 발생")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 20),
              Text(ocrVM.errorMessage!),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => ocrVM.clear(),
                child: const Text("다시 시도"),
              ),
            ],
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
      _isDataLoaded = false; // 데이터 로드 상태 초기화
      _choiceControllers.clear(); // 컨트롤러 초기화

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
              "문제집 스캔 결과",
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
    // 4. 결과 확인 및 수정 화면 (Form)
    // ---------------------------------------------------------

    // OCR 결과가 처음 들어왔을 때만 컨트롤러에 값을 채워넣습니다.
    if (!_isDataLoaded && ocrVM.ocrResult != null) {
      _problemController.text = ocrVM.ocrResult!['problem'] ?? "";

      // 선지 컨트롤러 초기화
      final choices = List<String>.from(ocrVM.ocrResult!['choices'] ?? []);
      _choiceControllers = choices
          .map((c) => TextEditingController(text: c))
          .toList();

      _isDataLoaded = true; // 로드 완료 표시
    }

    // 폴더 자동 선택
    if (_selectedFolderId == null && folderVM.folders.isNotEmpty) {
      _selectedFolderId = folderVM.folders[0].id;
    } else if (_selectedFolderId != null && folderVM.folders.isNotEmpty) {
      final exists = folderVM.folders.any((f) => f.id == _selectedFolderId);
      if (!exists) {
        _selectedFolderId = folderVM.folders[0].id;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("문제집 스캔하기"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ocrVM.clear();
            setState(() => _isDataLoaded = false);
          },
        ),
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
                    "스캔한 문제를 수정하거나 세부 정보를 입력하세요.",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 30),

                  // 1. 문제 이름 (텍스트)
                  const Text(
                    "문제 지문",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildGrayInputContainer(
                    child: TextField(
                      controller: _problemController,
                      maxLines: 4, // 여러 줄 입력 가능
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "문제 이름",
                        // labelText: "문제 이름",
                        // floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 선지 수정 영역 (동적 리스트)
                  if (_choiceControllers.isNotEmpty) ...[
                    const Text(
                      "선지 목록",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: List.generate(_choiceControllers.length, (
                          index,
                        ) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 12.0,
                                    right: 10,
                                  ),
                                  child: Text(
                                    "①②③④⑤"[index % 5],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E2B58),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: _buildGrayInputContainer(
                                    child: TextField(
                                      controller: _choiceControllers[index],
                                      maxLines: null, // 여러 줄 허용
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: "선지 ${index + 1}",
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 2. 문제 정답
                  const Text(
                    "정답",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildGrayInputContainer(
                    child: TextField(
                      controller: _answerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "예: 3",
                        hintStyle: TextStyle(color: Colors.grey),
                        contentPadding: EdgeInsets.all(10),
                        // labelText: "문제 정답",
                        // floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. 저장 폴더
                  const Text(
                    "저장 폴더",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // 드롭다운 (왼쪽)
                      Expanded(
                        child: _buildGrayInputContainer(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<int>(
                              key: ValueKey(_selectedFolderId),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.all(10),
                              ),
                              value: _selectedFolderId,
                              isExpanded: true,
                              hint: const Text(
                                "폴더 선택",
                                style: TextStyle(fontSize: 14),
                              ), // 힌트 텍스트 추가
                              items: folderVM.folders.map((folder) {
                                return DropdownMenuItem(
                                  value: folder.id,
                                  child: Text(
                                    folder.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() => _selectedFolderId = val);
                              },
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // 폴더 추가 버튼 (오른쪽)
                      SizedBox(
                        height: 50, // 높이를 드롭다운 박스와 맞춤
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E2B58),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                          ),
                          onPressed: () => _showAddFolderDialog(context),
                          child: const Text(
                            "폴더 추가",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // const Text(
                  //   "저장 폴더",
                  //   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  // ),
                  // const SizedBox(height: 8),
                  // _buildGrayInputContainer(
                  //   child: DropdownButtonHideUnderline(
                  //     child: DropdownButtonFormField<int>(
                  //       decoration: const InputDecoration(
                  //         border: InputBorder.none,
                  //         contentPadding: EdgeInsets.symmetric(horizontal: 10),
                  //         // labelText: "저장 폴더",
                  //         // floatingLabelBehavior: FloatingLabelBehavior.always,
                  //         // contentPadding: EdgeInsets.zero,
                  //       ),
                  //       value: _selectedFolderId,
                  //       isExpanded: true,
                  //       items: folderVM.folders.map((folder) {
                  //         return DropdownMenuItem(
                  //           value: folder.id,
                  //           child: Text(folder.name),
                  //         );
                  //       }).toList(),
                  //       onChanged: (val) {
                  //         setState(() => _selectedFolderId = val);
                  //       },
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 20),

                  // 4. 메모
                  const Text(
                    "메모",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  _buildGrayInputContainer(
                    height: 120,
                    child: TextField(
                      controller: _memoController,
                      maxLines: null,
                      minLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "메모를 입력하세요",
                        hintStyle: TextStyle(color: Colors.grey),
                        contentPadding: EdgeInsets.all(10),
                        // labelText: "메모",
                        // floatingLabelBehavior: FloatingLabelBehavior.always,
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
                        // [ver1] 사실 지금 화면이 수정 화면이므로, 키보드를 내리거나 하는 동작

                        // FocusScope.of(context).unfocus();
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(content: Text("내용을 수정해주세요.")),
                        // );

                        // [ver2] 초기화 로직
                        ocrVM.clear();
                        _problemController.clear();
                        _answerController.clear();
                        _memoController.clear();
                        setState(() => _isDataLoaded = false);
                      },
                      child: const Text(
                        "취소",
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
                        if (_selectedFolderId == null) {
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

                        // 수정된 선지 리스트 수집
                        List<String> finalChoices = _choiceControllers
                            .map((c) => c.text)
                            .toList();

                        // 저장 요청
                        final success = await ocrVM.saveProblem(
                          userVM.username,
                          _selectedFolderId!,
                          _answerController.text,
                          _problemController.text, // 수정된 문제 텍스트
                          finalChoices, // 수정된 선지 리스트 (참고: API가 지원해야 저장됨)
                          _memoController.text,
                          // []
                        );

                        if (success && context.mounted) {
                          await folderVM.loadFolders(userVM.username);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("저장 완료!")),
                          );
                          Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst);
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
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEBEFF5), // 연한 회색 배경
        borderRadius: BorderRadius.circular(12),
      ),
      // child: Center(child: child),
      child: child,
    );
  }

  // 폴더 추가 팝업 함수
  void _showAddFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    int selectedColorIndex = 0; // 기본 색상 인덱스

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text(
                '새 폴더 만들기',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "이름을 입력하세요.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: '예: 수학, 영어',
                      hintStyle: TextStyle(color: Colors.grey),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: Color(0xFF1E2B58),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "폴더 색상 선택",
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),

                  // 색상 선택 원들
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(_folderColors.length, (index) {
                      final color = _folderColors[index];
                      final isSelected = index == selectedColorIndex;
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            selectedColorIndex = index;
                          });
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.black, width: 2)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 20,
                                )
                              : null,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      final userVM = context.read<UserViewModel>();
                      final folderVM = context.read<FolderViewModel>();

                      // 선택된 색상 코드로 변환
                      final colorCode =
                          "0x${_folderColors[selectedColorIndex].value.toRadixString(16).toUpperCase()}";

                      // 폴더 생성 요청
                      final success = await folderVM.addFolder(
                        userVM.username,
                        name,
                        colorCode,
                      );

                      if (success && mounted) {
                        Navigator.pop(context); // 팝업 닫기

                        // [중요] 생성된 폴더를 드롭다운에서 바로 선택하도록 설정
                        if (folderVM.folders.isNotEmpty) {
                          setState(() {
                            _selectedFolderId = folderVM.folders.last.id;
                          });
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("'$name' 폴더가 생성되었습니다.")),
                        );
                      }
                    }
                  },
                  child: const Text(
                    '생성',
                    style: TextStyle(
                      color: Color(0xFF1E2B58),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
