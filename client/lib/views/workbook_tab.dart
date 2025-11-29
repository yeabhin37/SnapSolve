import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_view_model.dart';
import '../viewmodels/folder_view_model.dart';
import 'problem/solve_screen.dart';

class WorkbookTab extends StatefulWidget {
  const WorkbookTab({super.key});

  @override
  State<WorkbookTab> createState() => _WorkbookTabState();
}

class _WorkbookTabState extends State<WorkbookTab> {
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
                    itemCount: folderVM.folders.length,
                    itemBuilder: (context, index) {
                      final folderName = folderVM.folders[index];
                      // 색상 랜덤하게 돌리기 (민트, 네이비, 그레이)
                      final iconColor = [
                        const Color(0xFF2EBA9F),
                        const Color(0xFF1E2B58),
                        Colors.grey,
                      ][index % 3];

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SolveScreen(folderName: folderName),
                            ),
                          );
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
                                  color: iconColor,
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
                                    folderName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Text(
                                    "2025.10.09",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              const Icon(Icons.more_horiz, color: Colors.grey),
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
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () => _showAddFolderDialog(context),
      ),
    );
  }

  void _showAddFolderDialog(BuildContext context) {
    // 기존과 동일한 로직 (생략하거나 4단계 답변의 코드 복사)
    // ...
  }
}
