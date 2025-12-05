import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_view_model.dart';
import '../viewmodels/folder_view_model.dart';
import 'ocr_preview_screen.dart';
import 'solve_screen.dart';
import 'statistics_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
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
    final folderCount = folderVM.folders.length;
    final accuracy = folderVM.accuracy;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/logo_01.png', width: 60, height: 60),
            const SizedBox(width: 2),
            const Text(
              "찍고풀고",
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w800,
                fontSize: 24,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 일러스트 및 메인 텍스트
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.account_circle,
                    size: 80,
                    color: Color(0xFF1E2B58),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "나만의 맞춤형 디지털 학습지",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2B58),
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "문제집을 찍어서 나만의 문제은행을 만들어보세요.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 2. 문제집 스캔하기 버튼 (메인 액션)
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: const Text(
                  "문제집 스캔하기",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2B58),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OcrPreviewScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),

            // 3. 학습 대시보드
            const Text(
              "학습 대시보드",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2B58),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildDashboardCard(
                  "내 문제집",
                  "${folderCount}권",
                  Icons.library_books,
                  Colors.teal,
                ),
                const SizedBox(width: 15),
                _buildDashboardCard(
                  "정답률",
                  "$accuracy%",
                  Icons.check_circle_outline,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 4. 바로가기 메뉴
            const Text(
              "바로가기",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2B58),
              ),
            ),
            const SizedBox(height: 15),
            InkWell(
              onTap: () {
                // 오답노트 모드로 이동 (folderId: -1, isWrongNoteMode: true)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SolveScreen(
                      folderName: "오답노트",
                      folderId: -1,
                      isWrongNoteMode: true,
                    ),
                  ),
                );
              },
              child: _buildShortcutCard(
                "오답노트",
                "틀린 문제를 다시 풀어보세요",
                Icons.edit, // [수정] 연필 아이콘
                const Color(0xFF009688), // (홈 화면 디자인상 초록색 유지, 원하면 빨강으로 변경 가능)
              ),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatisticsScreen()),
                );
              },
              child: _buildShortcutCard(
                "학습 통계",
                "나의 학습 현황을 확인하세요",
                Icons.bar_chart,
                const Color(0xFF1E2B58),
              ),
            ),
            // _buildShortcutCard(
            //   "학습 통계",
            //   "나의 학습 현황을 확인하세요",
            //   Icons.bar_chart,
            //   const Color(0xFF1E2B58),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E2B58),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShortcutCard(
    String title,
    String subtitle,
    IconData icon,
    Color iconBgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: iconBgColor,
            radius: 22,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2B58),
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
