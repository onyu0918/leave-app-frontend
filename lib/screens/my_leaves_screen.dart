import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/logout_util.dart';
import '../services/leave_service.dart';
import 'package:intl/intl.dart';

class MyLeavesScreen extends StatefulWidget {
  const MyLeavesScreen({Key? key}) : super(key: key);

  @override
  _MyLeavesScreenState createState() => _MyLeavesScreenState();
}

class _MyLeavesScreenState extends State<MyLeavesScreen> {
  List<Map<String, dynamic>> leaves = [];
  bool isLoading = true;
  Map<int, bool> isDeleting = {};
  double availableLeaves = 0;
  double usedLeaves = 0;
  double pendingLeaves = 0;
  double approvedLeaves = 0;
  String username = '';
  String selectedStatus = '全て';
  int selectedMonthRange = 3;

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
    _loadLeaveData();
  }

  Future<void> _loadLeaveData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final leaveData = await LeaveService().fetchLeaveData();
      setState(() {
        username = leaveData['name'] ?? '';
        availableLeaves = leaveData['availableLeaves'] ?? 0;
        usedLeaves = leaveData['usedLeaves'] ?? 0;
        pendingLeaves = leaveData['pendingLeaves'] ?? 0;
        approvedLeaves = leaveData['approvedLeaves'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _confirmAndCancel(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('引き戻し確認'),
        content: const Text('この休暇申請をキャンセルしてもよろしいですか？'),
        actions: [
          TextButton(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('確認'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        isDeleting[id] = true;
      });
      try {
        await ApiService.updateUserLeaveStatus(id, 2);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('休暇申請が取り消されました。')),
        );
        _fetchLeaves();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('キャンセルに失敗いたしました: $e')),
        );
      } finally {
        setState(() {
          isDeleting[id] = false;
        });
      }
    }
  }

  Future<void> _fetchLeaves() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await ApiService.getUserLeaves();
      setState(() {
        leaves = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('有給休暇の照会に失敗しました: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _confirmLogout(BuildContext context) {
    logout(context);
  }

  Widget _styledButton(String label, IconData icon, VoidCallback? onPressed, {Color? color}) {
    return Expanded(
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.grey.shade800,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }

  String getStatusText(int status) {
    switch (status) {
      case 0:
        return '申請中';
      case 1:
        return '承認済み';
      case 2:
        return '却下済み';
      default:
        return 'Error';
    }
  }

  List<Map<String, dynamic>> get filteredLeaves {
    final now = DateTime.now();
    final cutoffDate = DateTime(now.year, now.month - selectedMonthRange);

    return leaves.where((leave) {
      final startDate = DateTime.tryParse(leave['startDate'] ?? '') ?? now;
      final statusText = getStatusText(leave['status']);

      final matchesStatus = selectedStatus == '全て' || selectedStatus == statusText;
      final withinPeriod = startDate.isAfter(cutoffDate);

      return matchesStatus && withinPeriod;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 6,
        shadowColor: Colors.black54,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('私の休暇一覧'),
            Flexible(
              child: Text(
                '残りの休暇 $availableLeaves 日。',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ログアウト',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'ステータス: ',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    DropdownButton<String>(
                      value: selectedStatus,
                      items: ['全て', '申請中', '承認済み', '却下済み'].map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value!;
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Text(
                      '期間: ',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    DropdownButton<int>(
                      value: selectedMonthRange,
                      items: [3, 6, 9, 12, 24].map((month) {
                        return DropdownMenuItem(
                          value: month,
                          child: Text('$monthヶ月'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedMonthRange = value!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),
            Expanded(
              child: filteredLeaves.isEmpty
                  ? const Center(child: Text('条件に一致する休暇申請はありません。'))
                  : ListView.builder(
                itemCount: filteredLeaves.length,
                itemBuilder: (context, index) {
                  final leave = filteredLeaves[index];
                  final id = leave['id'];
                  final date = DateTime.parse(leave['createdDate']);
                  final formatted = DateFormat('yyyy-MM-dd').format(date);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Text(
                        //   '申請日: ${leave['startDate']} ~ ${leave['endDate']} (${leave['days']}日)',
                        //   style: const TextStyle(fontWeight: FontWeight.bold),
                        // ),
                        Text('申請日: $formatted'),
                        Text('状態: ${getStatusText(leave['status'])}'),
                        const SizedBox(height: 8),
                        Text('申請期間: ${leave['startDate']} ~ ${leave['endDate']} (${leave['days']}日)'),
                        Text('残り有給: $availableLeaves日'),
                        Text('理由: ${leave['reason']}'),
                        if (leave['comment'] != null && leave['comment'].toString().trim().isNotEmpty)
                          Text('コメント: ${leave['comment']}', style: const TextStyle(color: Colors.black87)),
                        const SizedBox(height: 12),
                        if (leave['status'] == 0)
                          Row(
                            children: [
                              _styledButton(
                                '引き戻し',
                                Icons.cancel,
                                isDeleting[id] == true ? null : () => _confirmAndCancel(id),
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
