import 'package:flutter/material.dart';
import 'leave_request_screen.dart';
import 'my_leaves_screen.dart';
import '../utils/logout_util.dart';
import '../services/api_service.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int availableLeaves = 0;
  int usedLeaves = 0;
  bool isLoading = true;
  String username = '';

  @override
  void initState() {
    super.initState();
    _fetchLeaveData();
  }

  void _fetchLeaveData() async {
    try {
      final userresponse = await ApiService.getCurrentUser();
      final data = userresponse['data'];
      if (data == null || data['joinDate'] == null) {
        throw Exception('입사일 정보가 없습니다.');
      }

      final joinDate = DateTime.parse(data['joinDate']);
      final today = DateTime.now();

      DateTime resetDate = DateTime(today.year, joinDate.month, joinDate.day);
      if (today.isBefore(resetDate)) {
        resetDate = DateTime(today.year - 1, joinDate.month, joinDate.day);
      }

      final response = await ApiService.getUserLeaves();
      int usedDays = 0;

      for (var leave in response) {
        if (leave['status'] != 'APPROVED') continue;

        final start = DateTime.parse(leave['startDate']);
        final end = DateTime.parse(leave['endDate']);

        if (end.isBefore(resetDate)) continue;

        final effectiveStart = start.isBefore(resetDate) ? resetDate : start;

        usedDays += end.difference(effectiveStart).inDays + 1;
      }

      final totalLeaves = calculateTotalLeaves(joinDate, today);

      setState(() {
        availableLeaves = totalLeaves - usedDays;
        usedLeaves = usedDays;
        isLoading = false;
        username = data['username'];
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('연차 조회 실패: $e'),
      ));
    }
  }

  int calculateTotalLeaves(DateTime joinDate, DateTime today) {
    if (today.isBefore(joinDate)) return 0;

    DateTime resetDate = DateTime(today.year, joinDate.month, joinDate.day);
    if (today.isBefore(resetDate)) {
      resetDate = DateTime(today.year - 1, joinDate.month, joinDate.day);
    }

    int yearsSinceJoin = resetDate.year - joinDate.year;
    int monthsSinceReset = (today.year - resetDate.year) * 12 + today.month - resetDate.month;
    if (today.day < joinDate.day) monthsSinceReset--;

    if (resetDate.year == joinDate.year) {
      int monthsWorked = (today.year - joinDate.year) * 12 + (today.month - joinDate.month);
      if (today.day < joinDate.day) monthsWorked--;
      return monthsWorked.clamp(0, 10);
    }

    int totalLeaves = 0;
    switch (yearsSinceJoin) {
      case 1:
        totalLeaves = monthsSinceReset.clamp(0, 11);
        break;
      case 2:
        totalLeaves += (monthsSinceReset >= 0 ? 2 : 0);
        totalLeaves += (monthsSinceReset >= 1 ? 2 : 0);
        totalLeaves += (monthsSinceReset - 2).clamp(0, 10);
        totalLeaves = totalLeaves.clamp(0, 12);
        break;
      case 3:
        totalLeaves += (monthsSinceReset >= 0 ? 2 : 0);
        totalLeaves += (monthsSinceReset >= 1 ? 2 : 0);
        totalLeaves += (monthsSinceReset >= 2 ? 2 : 0);
        totalLeaves += (monthsSinceReset - 3).clamp(0, 10);
        totalLeaves = totalLeaves.clamp(0, 13);
        break;
      case 4:
        totalLeaves += (monthsSinceReset >= 0 ? 2 : 0);
        totalLeaves += (monthsSinceReset >= 1 ? 2 : 0);
        totalLeaves += (monthsSinceReset >= 2 ? 2 : 0);
        totalLeaves += (monthsSinceReset >= 3 ? 2 : 0);
        totalLeaves += (monthsSinceReset - 4).clamp(0, 10);
        totalLeaves = totalLeaves.clamp(0, 14);
        break;
      default:
        totalLeaves = 999;
    }

    return totalLeaves;
  }

  void _confirmLogout(BuildContext context) {
    logout(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 140),
          Text(
            '$username 님',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          Text(
            '남은 연차: $availableLeaves 개',
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            '사용된 연차: $usedLeaves 개',
            style: const TextStyle(fontSize: 16),
          ),
          // const Spacer(),
          const SizedBox(height: 200),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LeaveRequestScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text('Leave\nRequest', textAlign: TextAlign.center),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      minimumSize: const Size.fromHeight(60),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyLeavesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.list_alt),
                    label: const Text('My\nLeave', textAlign: TextAlign.center),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      minimumSize: const Size.fromHeight(60),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Expanded(
                //   child: ElevatedButton.icon(
                //     onPressed: () => _confirmLogout(context),
                //     icon: const Icon(Icons.logout),
                //     label: const Text('Logout', textAlign: TextAlign.center),
                //     style: ElevatedButton.styleFrom(
                //       padding: const EdgeInsets.all(12),
                //       minimumSize: const Size.fromHeight(60),
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
