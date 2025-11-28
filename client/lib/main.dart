import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'viewmodels/user_view_model.dart';
import 'viewmodels/folder_view_model.dart';
import 'views/splash_screen.dart';
import 'viewmodels/ocr_view_model.dart';

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
      ],
      child: MaterialApp(
        title: 'SnapSolve',
        debugShowCheckedModeBanner: false, // 오른쪽 위 'Debug' 띠 제거
        theme: ThemeData(
          // PDF 디자인과 비슷한 남색 테마
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E3A8A)),
          useMaterial3: true,
        ),
        home: const SplashScreen(), // 여기가 시작 화면입니다!
      ),
    );
  }
}
