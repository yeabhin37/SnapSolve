// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/user_view_model.dart';
import 'viewmodels/folder_view_model.dart';
import 'viewmodels/ocr_view_model.dart';
import 'viewmodels/solve_view_model.dart';
import 'views/splash_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserViewModel()),
        ChangeNotifierProvider(create: (_) => FolderViewModel()),
        ChangeNotifierProvider(create: (_) => OcrViewModel()),
        ChangeNotifierProvider(create: (_) => SolveViewModel()),
      ],
      child: MaterialApp(
        title: 'SnapSolve',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Pretendard',

          scaffoldBackgroundColor: Colors.white, // 전체 배경 흰색
          // 프로토타입 컬러 팔레트 적용
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1E2B58), // 진한 네이비 (메인 버튼, 헤더)
            secondary: Color(0xFF2EBA9F), // 민트 (정답, 포인트)
            surface: Color(0xFFF3F4F6), // 연한 회색 (입력창 배경)
            onSurface: Color(0xFF111827), // 기본 검은 글씨
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1E2B58),
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Color(0xFF1E2B58),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E2B58),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
