import 'package:flutter/material.dart';
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
    const HomeTab(), // 홈 (대시보드)
    const WorkbookTab(), // 문제집 (폴더 목록)
    const Center(child: Text("스캔 화면은 버튼으로 동작합니다")), // 스캔 (자리만 차지)
    const Center(child: Text("마이페이지 준비중")), // 마이페이지
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectedIndex == 2
          ? _screens[0] // 스캔 버튼 눌러도 배경은 홈 유지 (실제 이동은 버튼 로직에서)
          : IndexedStack(index: _selectedIndex, children: _screens),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 2) {
            // TODO: 스캔 화면으로 이동 (여기선 탭 이동 안함)
            // HomeTab의 스캔 버튼과 동일한 로직 연결 필요
          } else {
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
}
