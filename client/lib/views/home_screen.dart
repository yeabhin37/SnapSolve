import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_view_model.dart';
import '../viewmodels/folder_view_model.dart';
import 'ocr_preview_screen.dart'; // 다음 단계에서 주석 해제
// import 'problem/problem_list_screen.dart'; // 다음 단계에서 주석 해제
import 'solve_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 화면이 열리자마자 폴더 목록 불러오기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final username = context.read<UserViewModel>().username;
      context.read<FolderViewModel>().loadFolders(username);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userVM = context.watch<UserViewModel>();
    final folderVM = context.watch<FolderViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 문제집'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => folderVM.loadFolders(userVM.username),
          ),
        ],
      ),
      body: folderVM.isLoading
          ? const Center(child: CircularProgressIndicator())
          : folderVM.folders.isEmpty
          ? const Center(child: Text('폴더를 추가하고 학습을 시작해보세요!'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: folderVM.folders.length,
              itemBuilder: (context, index) {
                final folder = folderVM.folders[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(
                      Icons.folder,
                      color: Colors.amber,
                      size: 40,
                    ),
                    title: Text(
                      folder.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text('문제 풀러 가기'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SolveScreen(folderName: folder.name),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 폴더 추가 버튼
          FloatingActionButton(
            heroTag: 'add_folder',
            backgroundColor: Colors.white,
            foregroundColor: Colors.indigo,
            onPressed: () => _showAddFolderDialog(context),
            child: const Icon(Icons.create_new_folder),
          ),
          const SizedBox(height: 16),
          // 문제 촬영 버튼 (핵심 기능)
          FloatingActionButton.extended(
            heroTag: 'camera',
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OcrPreviewScreen()),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('문제 촬영'),
          ),
        ],
      ),
    );
  }

  // 폴더 추가 팝업창
  void _showAddFolderDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 폴더 만들기'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '과목명 (예: 수학, 영어)'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final userVM = context.read<UserViewModel>();
                final folderVM = context.read<FolderViewModel>();

                final success = await folderVM.addFolder(
                  userVM.username,
                  controller.text,
                  "0xFF1E2B58",
                );
                if (success && context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('생성'),
          ),
        ],
      ),
    );
  }
}
