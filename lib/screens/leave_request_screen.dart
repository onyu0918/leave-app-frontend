import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({Key? key}) : super(key: key);

  @override
  _LeaveRequestScreenState createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _applyLeave() async {
    if (_startDate == null || _endDate == null || _reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('모든 항목을 입력해주세요.'),
      ));
      return;
    }

    final startDate = DateFormat('yyyy-MM-dd').format(_startDate!);
    final endDate = DateFormat('yyyy-MM-dd').format(_endDate!);
    final reason = _reasonController.text;

    try {
      await ApiService.applyLeave(startDate, endDate, reason);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('연차 신청이 완료되었습니다.'),
      ));
      setState(() {
        _startDate = null;
        _endDate = null;
        _reasonController.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('연차 신청 실패: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Leave'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _startDate == null
                        ? '시작일 선택 안됨'
                        : '시작일: ${dateFormat.format(_startDate!)}',
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDate(context, true),
                  child: const Text('시작일 선택'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _endDate == null
                        ? '종료일 선택 안됨'
                        : '종료일: ${dateFormat.format(_endDate!)}',
                  ),
                ),
                TextButton(
                  onPressed: () => _selectDate(context, false),
                  child: const Text('종료일 선택'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: '사유'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _applyLeave,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
              child: const Text(
                '연차 신청',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
