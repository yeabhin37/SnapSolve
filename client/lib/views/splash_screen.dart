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
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final userViewModel = Provider.of<UserViewModel>(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt, size: 80, color: Color(0xFF1E3A8A)),
              const SizedBox(height: 20),
              const Text(
                '찍고풀고',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text('나만의 맞춤형 디지털 학습지'),
              const SizedBox(height: 50),

              TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: '닉네임 입력',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: userViewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final name = _controller.text.trim();
                          if (name.isNotEmpty) {
                            final success = await userViewModel.login(name);
                            if (success && context.mounted) {
                              // 로그인 성공 시 홈 화면으로 이동 (뒤로가기 불가)
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MainNavScreen(),
                                ),
                              );
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('로그인 실패: 서버를 확인해주세요'),
                                ),
                              );
                            }
                          }
                        },
                        child: const Text(
                          '시작하기',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
