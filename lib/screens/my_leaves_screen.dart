import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MyLeavesScreen extends StatefulWidget {
  const MyLeavesScreen({Key? key}) : super(key: key);

  @override
  _MyLeavesScreenState createState() => _MyLeavesScreenState();
}

class _MyLeavesScreenState extends State<MyLeavesScreen> {
  List<Map<String, dynamic>> leaves = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  void _fetchLeaves() async {
    try {
      final response = await ApiService.getUserLeaves();
      setState(() {
        leaves = response;
        isLoading = false;
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

  void _confirmAndDelete(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('정말 이 연차 신청을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('삭제'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteLeave(id);
        _fetchLeaves(); // 삭제 후 목록 다시 불러오기
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연차 신청이 삭제되었습니다.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 연차 신청 내역'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : leaves.isEmpty
          ? const Center(child: Text('신청 내역이 없습니다.'))
          : ListView.builder(
        itemCount: leaves.length,
        itemBuilder: (context, index) {
          final leave = leaves[index];
          final status = leave['status'];
          final statusText = status == 'APPROVED'
              ? '승인됨'
              : status == 'REJECTED'
              ? '거절됨'
              : '대기 중';
          final rejectReason = leave['rejectReason'];

          return Card(
            margin:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              leading: const Icon(Icons.event_note),
              title: Text(
                '${leave['startDate']} ~ ${leave['endDate']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('사유: ${leave['reason']}'),
                  Text('상태: $statusText'),
                  if (status == 'REJECTED' && rejectReason != null)
                    Text('거절 사유: $rejectReason'),
                ],
              ),
              trailing: status == 'PENDING'
                  ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.grey),
                onPressed: () => _confirmAndDelete(leave['id']),
              )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
