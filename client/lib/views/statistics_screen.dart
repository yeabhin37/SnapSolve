import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../viewmodels/folder_view_model.dart';
import '../../viewmodels/user_view_model.dart';
import '../../services/api_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // 탭 선택 상태 (UI용 더미)
  int _selectedTabIndex = 0; // 0: 주간, 1: 월간, 2: 전체

  // 그래프용 데이터
  List<Map<String, dynamic>> _historyData = [];
  bool _isHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    // 데이터 최신화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final username = context.read<UserViewModel>().username;
      context.read<FolderViewModel>().loadFolders(username);
      _loadHistory(username);
    });
  }

  // 서버에서 점수 기록 가져오기
  Future<void> _loadHistory(String username) async {
    final data = await ApiService().getExamHistory(username);
    if (mounted) {
      setState(() {
        _historyData = data;
        _isHistoryLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final folderVM = context.watch<FolderViewModel>();

    // 전체 정답률 계산
    final accuracy = folderVM.accuracy; // API에서 받아온 값
    // (임시) 푼 문제가 없으면 0으로 표시
    final double accuracyRate = accuracy / 100.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // 배경색 (회색톤)
      appBar: AppBar(
        title: const Text("학습 통계"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF1E2B58),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 1. 상단 탭 (주간/월간/전체) - 기능은 없지만 디자인 구현
            _buildSegmentedControl(),
            const SizedBox(height: 20),

            // 2. 전체 정답률 카드 (원형 차트)
            _buildOverallAccuracyCard(accuracy, accuracyRate),
            const SizedBox(height: 20),

            // // 3. 폴더별(과목별) 현황 카드
            // _buildFolderStatsCard(folderVM),
            // const SizedBox(height: 20),

            // 4. 점수 변화 추이 (실제 그래프)
            _buildTrendChartCard(),
          ],
        ),
      ),
    );
  }

  // 점수 변화 추이 그래프 (fl_chart)
  Widget _buildTrendChartCard() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "점수 변화 추이",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "최근 10회",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 30),

          AspectRatio(
            aspectRatio: 2.10,
            child: _isHistoryLoading
                ? const Center(child: CircularProgressIndicator())
                : _historyData.isEmpty
                ? const Center(
                    child: Text(
                      "아직 푼 문제가 없습니다.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      // [수정] 가로선(Grid) 추가하여 점수 보기 편하게 함
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false, // 세로선은 숨김
                        horizontalInterval: 20, // 20점 단위로 선 그리기
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.shade100,
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        // [수정] X축(날짜) 숨김
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        // [수정] Y축(점수) 표시
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 20, // 0, 20, 40... 단위
                            reservedSize: 35, // 글자 공간 확보
                            getTitlesWidget: (value, meta) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Text(
                                  value.toInt().toString(),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (_historyData.length - 1).toDouble(),
                      minY: 0,
                      maxY: 100, // 100점보다 살짝 높게 잡아서 잘림 방지
                      lineBarsData: [
                        LineChartBarData(
                          spots: _historyData.asMap().entries.map((e) {
                            return FlSpot(
                              e.key.toDouble(),
                              (e.value['score'] as int).toDouble(),
                            );
                          }).toList(),
                          isCurved: true,
                          color: const Color(0xFF1E2B58),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            // 그라데이션 효과 추가
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF1E2B58).withOpacity(0.3),
                                const Color(0xFF1E2B58).withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: ["주간", "월간", "전체"].asMap().entries.map((entry) {
          final index = entry.key;
          final text = entry.value;
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? const Color(0xFF1E2B58) : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverallAccuracyCard(int accuracy, double rate) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "전체 정답률",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 12,
                  backgroundColor: const Color(0xFFF0F0F0),
                  color: const Color(0xFF2EBA9F),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                children: [
                  Text(
                    "$accuracy%",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2B58),
                    ),
                  ),
                  const Text(
                    "정답률",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFolderStatsCard(FolderViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "폴더별 문제 수",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (vm.folders.isEmpty)
            const Center(
              child: Text(
                "생성된 폴더가 없습니다.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ...vm.folders.map((folder) {
            double percent = (folder.problemCount / 50).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      folder.name,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFF0F0F0),
                        color: const Color(0xFF1E2B58),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "${folder.problemCount}개",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
