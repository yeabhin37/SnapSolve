import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/user_view_model.dart';
import 'main_nav_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _pwController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo_01.png', width: 120, height: 120),
              const SizedBox(height: 20),
              const Text(
                '찍고풀고',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                '나만의 맞춤형 디지털 학습지',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // 아이디 입력
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: '아이디',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 10),

              // 비밀번호 입력
              TextField(
                controller: _pwController,
                obscureText: true, // 비밀번호 가리기
                decoration: const InputDecoration(
                  labelText: '비밀번호',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),

              // 버튼 영역
              if (userViewModel.isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    // 로그인 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final id = _idController.text.trim();
                          final pw = _pwController.text.trim();

                          if (id.isEmpty || pw.isEmpty) return;

                          final success = await userViewModel.login(id, pw);
                          if (success && context.mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const MainNavScreen(),
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('로그인 실패: 아이디/비번을 확인하세요'),
                              ),
                            );
                          }
                        },
                        child: const Text(
                          '로그인',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 회원가입 버튼 (텍스트 버튼)
                    TextButton(
                      onPressed: () async {
                        final id = _idController.text.trim();
                        final pw = _pwController.text.trim();

                        if (id.isEmpty || pw.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('아이디와 비밀번호를 입력해주세요')),
                          );
                          return;
                        }

                        final success = await userViewModel.register(id, pw);
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('가입 성공! 로그인 해주세요.')),
                          );
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('가입 실패: 이미 존재하는 아이디입니다.'),
                            ),
                          );
                        }
                      },
                      child: const Text('회원가입 하기'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
