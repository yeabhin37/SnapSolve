import 'package:flutter/material.dart';

// [PrimaryButton]
// 앱의 메인 색상(네이비)을 사용하는 강조 버튼
// 높이 55, 모서리 반경 12로 통일된 디자인 제공
class PrimaryButton extends StatelessWidget {
  final String text; // 버튼 텍스트
  final VoidCallback onPressed; // 클릭 이벤트 콜백
  final double height; // 버튼 높이 (기본값 55)

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 55,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, // 가로 꽉 채움
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E2B58), // 진한 네이비
          foregroundColor: Colors.white, // 글자색 흰색
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0, // 그림자 제거 (플랫 디자인)
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// [SecondaryButton]
// 취소하거나 덜 중요한 액션을 위한 회색 버튼
class SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final double height;

  const SecondaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.height = 55,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEBEFF5), // 연한 회색 배경
          foregroundColor: Colors.black87, // 진한 회색 글자
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
