import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/leave_service.dart';
import '../utils/logout_util.dart';
import 'user_home_screen.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({Key? key}) : super(key: key);

  @override
  _LeaveRequestScreenState createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  double availableLeaves = 0.0;
  double usedLeaves = 0.0;
  String username = '';
  bool isLoading = true;
  double _workingDays = 0.0;
  bool _isHalfDay = false;

  String? _startDateError;
  String? _endDateError;

  @override
  void initState() {
    super.initState();
    _loadLeaveData();
  }

  void _confirmLogout(BuildContext context) {
    logout(context);
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
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? _startDate ?? DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: isStart ? DateTime(2022) : (_startDate ?? DateTime(2022)),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startDateError = null;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
            _endDateError = '終了日は開始日以降を選択してください。';
          } else {
            _endDateError = null;
          }
        } else {
          _endDate = picked;
          _endDateError = null;
        }
      });

      if (_startDate != null && _endDate != null) {
        final days = await LeaveService().calculateWorkingDays(_startDate!, _endDate!);
        setState(() {
          _workingDays = days.toDouble();
        });
      } else {
        setState(() {
          _workingDays = 0;
        });
      }
    }
  }

  bool _validateDates() {
    bool valid = true;
    setState(() {
      if (_startDate == null) {
        _startDateError = '開始日を選択してください。';
        valid = false;
      } else {
        _startDateError = null;
      }
      if (_endDate == null) {
        _endDateError = '終了日を選択してください。';
        valid = false;
      } else if (_startDate != null && _endDate!.isBefore(_startDate!)) {
        _endDateError = '終了日は開始日以降を選択してください。';
        valid = false;
      } else {
        _endDateError = null;
      }
    });
    return valid;
  }

  Future<void> _onHalfDayToggle(bool? value) async {
    setState(() {
      _isHalfDay = value ?? false;

      if (_isHalfDay) {
        if (_startDate == null) {
          _startDateError = '開始日を選択してください。';
          _isHalfDay = false;
          _workingDays = 0;
          return;
        }

        if (_endDate != null && _endDate != _startDate) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('注意'),
              content: Text('反日休暇を選択するには、開始日と終了日が同じである必要があります。\n終了日をリセットしますか？'),
              actions: [
                TextButton(
                  child: Text('キャンセル'),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _isHalfDay = false;
                    });
                  },
                ),
                TextButton(
                  child: Text('リセット'),
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() {
                      _endDate = _startDate;
                      _workingDays = 0.5;
                      _endDateError = null;
                    });
                  },
                ),
              ],
            ),
          );
        } else {
          _endDate = _startDate;
          _workingDays = 0.5;
          _endDateError = null;
        }
      }
    });

    if (!_isHalfDay && _startDate != null && _endDate != null) {
      final days = await LeaveService().calculateWorkingDays(_startDate!, _endDate!);
      setState(() {
        _workingDays = days.toDouble();
      });
    }
  }


  Future<void> _applyLeave() async {
    if (!_validateDates() || !_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('すべての項目を正しく入力してください。'),
      ));
      return;
    }

    // final reason = _reasonController.text.trim();
    // if (reason.length < 5) {
    //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    //     content: Text('申請理由は5文字以上入力してください。'),
    //   ));
    //   return;
    // }

    if (_workingDays > availableLeaves) {
      final extraDays = _workingDays - availableLeaves;
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('確認'),
          content: Text('申請日数は残りの休暇を超えています。\n'
              '残り: $availableLeaves 日\n'
              '申請: $_workingDays 日\n'
              '超過分: $extraDays 日\n'
              'それでも申請を続けますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('申請する'),
            ),
          ],
        ),
      );

      if (shouldProceed != true) {
        return;
      }
    }

    final startDate = DateFormat('yyyy-MM-dd').format(_startDate!);
    final endDate = DateFormat('yyyy-MM-dd').format(_endDate!);
    final reason = _reasonController.text;

    try {
      // await ApiService.applyLeave(startDate, endDate, reason, _workingDays);
      await ApiService.applyLeave(startDate, endDate, reason, _isHalfDay ? 0.5 : _workingDays);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('有給休暇の申請が正常に完了しました。'),
      ));
      setState(() {
        _startDate = null;
        _endDate = null;
        _reasonController.clear();
        _workingDays = 0;
        _startDateError = null;
        _endDateError = null;
      });
      _loadLeaveData();

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const UserHomeScreen()),
            (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('有給休暇の申請を完了できませんでした。: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 6,
        shadowColor: Colors.black54,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('休暇の申請'),
            Flexible(
              child: Text.rich(
                TextSpan(
                  text: '残りの休暇 ',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                  children: [
                    TextSpan(
                      text: '$availableLeaves',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(text: ' 日。'),
                  ],
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildDateSelector(
                label: _startDate == null
                    ? '開始日が選択されていません。'
                    : '開始日: ${dateFormat.format(_startDate!)}',
                errorText: _startDateError,
                onTap: () => _selectDate(context, true),
              ),
              const SizedBox(height: 16),
              _buildDateSelector(
                label: _endDate == null
                    ? '終了日を選択できません。'
                    : '終了日: ${dateFormat.format(_endDate!)}',
                errorText: _endDateError,
                onTap: () => _selectDate(context, false),
              ),
              const SizedBox(height: 16),
              if (_workingDays > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text.rich(
                      TextSpan(
                        text: '申請日数: ',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        children: [
                          TextSpan(
                            text: '${_workingDays.toStringAsFixed(1)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' 日'),
                        ],
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Checkbox(
                    value: _isHalfDay,
                    onChanged: _onHalfDayToggle,
                  ),
                  const Text('半日休暇を申請する'),
                ],
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextFormField(
                  controller: _reasonController,
                  decoration: const InputDecoration(
                    labelText: '理由',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  maxLines: 3,
                  validator: (value) =>
                  value == null || value.isEmpty ? '理由を入力してください' : null,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _applyLeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // if (_workingDays > 0)
                      //   Padding(
                      //     padding: const EdgeInsets.only(right: 8),
                      //     child: Text(
                      //         '${_workingDays.toStringAsFixed(1)} 日',
                      //       style: const TextStyle(fontSize: 18),
                      //     ),
                      //   ),
                      const Text(
                        '有給休暇申請',
                        style: TextStyle(fontSize: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildDateSelector({
    required String label,
    required VoidCallback onTap,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.edit_calendar,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
