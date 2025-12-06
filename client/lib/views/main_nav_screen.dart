import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../viewmodels/user_view_model.dart';
import '../viewmodels/ocr_view_model.dart';
import 'ocr_preview_screen.dart';
import 'home_tab.dart';
import 'workbook_tab.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  // 탭별 화면 정의
  final List<Widget> _screens = [
    const HomeTab(), // 0: 홈 (대시보드)
    const WorkbookTab(), // 1: 문제집 (폴더 관리)
    const SizedBox.shrink(), // 2: 스캔 (UI 없음, 버튼 클릭 이벤트로 대체)
    const Center(child: Text("마이페이지 준비중")), // 3: 마이페이지
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack을 사용하여 탭 전환 시 상태 유지
      body: IndexedStack(index: _selectedIndex, children: _screens),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            // 가운데 '스캔' 탭 클릭 시 바텀 시트 호출
            _showScanBottomSheet(context);
          } else {
            // 일반 탭 이동
            setState(() => _selectedIndex = index);
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1E2B58),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: '문제집'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt_outlined),
            label: '문제집 스캔',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '마이페이지'),
        ],
      ),
    );
  }

  // 스캔 방식 선택 모달 (카메라 vs 갤러리)
  void _showScanBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 핸들 바
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "문제집 스캔하기",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2B58),
                ),
              ),
              const SizedBox(height: 30),
              // 카메라 버튼
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E2B58),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _processScan(ImageSource.camera);
                  },
                  child: const Text(
                    "카메라로 스캔",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // 갤러리 버튼
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEBEFF5),
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _processScan(ImageSource.gallery);
                  },
                  child: const Text(
                    "갤러리에서 선택",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // 스캔 로직 실행 (ViewModel 호출 후 미리보기 화면 이동)
  void _processScan(ImageSource source) {
    // context가 유효한지 확인하고 접근
    if (!mounted) return;

    final userVM = context.read<UserViewModel>();
    final ocrVM = context.read<OcrViewModel>();

    // OCR 요청 시작
    ocrVM.pickAndScanImage(userVM.username, source);

    // 미리보기 화면으로 이동 (로딩 상태 표시됨)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OcrPreviewScreen()),
    );
  }
}
