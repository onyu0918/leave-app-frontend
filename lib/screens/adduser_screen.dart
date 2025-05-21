import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  DateTime? _selectedDate;
  bool _isAdmin = false;
  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final response = await ApiService.addUser(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
        isAdmin: _isAdmin,
        joinDate: formattedDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? '사용자 추가 완료')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('사용자 추가')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: '아이디'),
                validator: (value) => value == null || value.isEmpty ? '아이디를 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '비밀번호'),
                obscureText: true,
                validator: (value) => value == null || value.isEmpty ? '비밀번호를 입력하세요' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    _selectedDate == null
                        ? '입사일을 선택하세요'
                        : '입사일: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _pickDate,
                    child: const Text('날짜 선택'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                title: const Text('관리자 권한 부여'),
                value: _isAdmin,
                onChanged: (val) {
                  setState(() {
                    _isAdmin = val ?? false;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('사용자 추가'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
