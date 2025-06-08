import 'package:flutter/material.dart';
import 'package:badges/badges.dart' as badges;
import '../utils/logout_util.dart';
import '../services/api_service.dart';
import 'dart:async';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int pendingCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingLeaveCount();
  }

  Future<void> _fetchPendingLeaveCount() async {
    try {
      final count = await ApiService.getPendingLeaveCount();
      setState(() {
        pendingCount = count;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('休暇申請数の取得エラー: $e');
    }
  }

  void _confirmLogout(BuildContext context) {
    logout(context);
  }

  Widget _buildDashboardButton({
    required BuildContext context,
    required String text,
    required VoidCallback onPressed,
    int? badgeCount,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade600,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
            if (badgeCount != null && badgeCount > 0) ...[
              const SizedBox(width: 8),
              badges.Badge(
                badgeContent: Text(
                  '$badgeCount件',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                badgeStyle: const badges.BadgeStyle(
                  badgeColor: Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('管理者ダッシュボード'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDashboardButton(
              context: context,
              text: '休暇申請一覧を見る',
              badgeCount: pendingCount,
              onPressed: () {
                Navigator.pushNamed(context, '/admin/leave-requests');
              },
            ),
            _buildDashboardButton(
              context: context,
              text: 'ユーザーを管理する',
              onPressed: () {
                Navigator.pushNamed(context, '/admin/add-user');
              },
            ),
            _buildDashboardButton(
              context: context,
              text: '休暇カレンダーを見る',
              onPressed: () {
                Navigator.pushNamed(context, '/admin/calendar');
              },
            ),
          ],
        ),
      ),
    );
  }
}
