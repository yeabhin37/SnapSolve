import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_view_model.dart';
import '../viewmodels/folder_view_model.dart';
import '../models/folder_model.dart';
import 'solve_screen.dart';

class WorkbookTab extends StatefulWidget {
  const WorkbookTab({super.key});

  @override
  State<WorkbookTab> createState() => _WorkbookTabState();
}

class _WorkbookTabState extends State<WorkbookTab> {
  // 폴더 색상 팔레트 정의
  final List<Color> _folderColors = const [
    Color(0xFF1E2B58), // 네이비
    Color(0xFF2EBA9F), // 민트
    Color(0xFFE57373), // 코랄
    Color(0xFF64B5F6), // 블루
    Color(0xFFFBC02D), // 옐로우
    Color(0xFF546E7A), // 그레이
  ];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final username = context.read<UserViewModel>().username;
      context.read<FolderViewModel>().loadFolders(username);
    });
  }

  @override
  Widget build(BuildContext context) {
    final folderVM = context.watch<FolderViewModel>();
    final userVM = context.read<UserViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("문제집"),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.settings))],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "최근 학습 기록",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2B58),
              ),
            ),
          ),
          Expanded(
            child: folderVM.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: folderVM.folders.length + 1, // 오답노트용 1개
                    itemBuilder: (context, index) {
                      // 0번 인덱스는 무조건 '오답노트' 폴더
                      if (index == 0) {
                        return InkWell(
                          onTap: () {
                            // 오답노트 모드로 진입 (folderName에 특수 값 전달)
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SolveScreen(
                                  folderName: "오답노트",
                                  folderId: -1,
                                  isWrongNoteMode: true,
                                ),
                              ),
                            ).then((_) {
                              final username = context
                                  .read<UserViewModel>()
                                  .username;
                              context.read<FolderViewModel>().loadFolders(
                                username,
                              );
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 15),
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE65A5A),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "오답노트",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      "${folderVM.wrongNoteCount}문제",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                // 오답노트는 수정/삭제 메뉴 없음
                              ],
                            ),
                          ),
                        );
                      }

                      final folder = folderVM.folders[index - 1];
                      // 서버에서 받은 Hex String -> Color 객체 변환
                      final colorInt = int.parse(folder.color);
                      final folderColor = Color(colorInt);

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SolveScreen(
                                folderName: folder.name,
                                folderId: folder.id,
                              ),
                            ),
                          ).then((_) {
                            final username = context
                                .read<UserViewModel>()
                                .username;
                            context.read<FolderViewModel>().loadFolders(
                              username,
                            );
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: folderColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.folder,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    folder.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${folder.problemCount}문제",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              PopupMenuButton<String>(
                                icon: const Icon(
                                  Icons.more_horiz,
                                  color: Colors.grey,
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showFolderDialog(context, folder: folder);
                                  } else if (value == 'delete') {
                                    _deleteFolder(userVM.username, folder.id);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('폴더 수정'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      '폴더 삭제',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1E2B58),
        shape: const CircleBorder(),
        child: const Icon(Icons.create_new_folder, color: Colors.white),
        onPressed: () => _showFolderDialog(context),
      ),
    );
  }

  void _deleteFolder(String username, int folderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("폴더 삭제"),
        content: const Text("정말로 삭제하시겠습니까?\n폴더 안의 모든 문제도 삭제됩니다."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<FolderViewModel>().removeFolder(username, folderId);
    }
  }

  void _showFolderDialog(BuildContext context, {Folder? folder}) {
    final isEdit = folder != null;
    final controller = TextEditingController(text: isEdit ? folder.name : '');

    // 선택된 색상 관리 (초기값: 수정이면 기존색, 생성이면 첫번째 색)
    int selectedColorIndex = 0;
    if (isEdit) {
      final colorInt = int.parse(folder.color);
      final index = _folderColors.indexWhere((c) => c.value == colorInt);
      if (index != -1) selectedColorIndex = index;
    }

    showDialog(
      context: context,
      builder: (context) {
        // StatefulBuilder를 써야 다이얼로그 내부에서 setState가 먹힘
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                isEdit ? '폴더 수정' : '새 폴더 만들기',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
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
                    autofocus: !isEdit,
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

                  // 색상 선택 원들 (Row)
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
                                ? Border.all(
                                    color: Colors.black,
                                    width: 2,
                                  ) // 선택 시 테두리
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
                // 취소 버튼
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '취소',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // 폴더 생성 버튼
                TextButton(
                  onPressed: () async {
                    final name = controller.text.trim();
                    if (name.isNotEmpty) {
                      final userVM = context.read<UserViewModel>();
                      final folderVM = context.read<FolderViewModel>();
                      final colorCode =
                          "0x${_folderColors[selectedColorIndex].value.toRadixString(16).toUpperCase()}";

                      bool success;
                      if (isEdit) {
                        success = await folderVM.editFolder(
                          userVM.username,
                          folder.id,
                          name,
                          colorCode,
                        );
                      } else {
                        success = await folderVM.addFolder(
                          userVM.username,
                          name,
                          colorCode,
                        );
                      }

                      if (success && context.mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: Text(
                    isEdit ? '수정' : '생성',
                    style: const TextStyle(
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
