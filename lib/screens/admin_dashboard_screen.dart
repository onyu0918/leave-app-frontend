import 'package:flutter/material.dart';
import '../utils/logout_util.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  void _confirmLogout(BuildContext context) {
    logout(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin/leave-requests');
              },
              child: const Text('연차 신청 목록 보기'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/admin/add-user');
              },
              child: const Text('사용자 추가'),
            ),
          ],
        ),
      ),
    );
  }
}
