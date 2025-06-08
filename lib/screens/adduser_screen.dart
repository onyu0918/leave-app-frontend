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
  final _editFormKey = GlobalKey<FormState>(); // 새로 추가

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _editUsernameController = TextEditingController();
  final TextEditingController _editPasswordController = TextEditingController();

  DateTime? _selectedDate;
  bool _isAdmin = false;
  bool _isSubmitting = false;
  bool _isEditting = false;
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _fetchAllUsers();
  }

  Future<void> _fetchAllUsers() async {
    setState(() {
      _isLoadingUsers = true;
    });
    try {
      final users = await ApiService.getAllUsers();
      setState(() {
        _allUsers = users;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ユーザー一覧の取得に失敗しました: $e')),
      );
    } finally {
      setState(() {
        _isLoadingUsers = false;
      });
    }
  }

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
        name: _nameController.text.trim(),
        isAdmin: _isAdmin,
        joinDate: formattedDate,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'ユーザーが正常に追加されました。')),
      );

      await _fetchAllUsers();

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
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
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildShadowInput({
    required TextEditingController controller,
    required String labelText,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
            // borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text('ユーザー追加')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildShadowInput(
                    controller: _usernameController,
                    labelText: 'ユーザーID',
                    validator: (value) =>
                    value == null || value.isEmpty ? 'ユーザーIDを入力してください' : null,
                  ),
                  _buildShadowInput(
                    controller: _passwordController,
                    labelText: 'パスワード',
                    obscure: true,
                    validator: (value) =>
                    value == null || value.isEmpty ? 'パスワードを入力してください' : null,
                  ),
                  _buildShadowInput(
                    controller: _nameController,
                    labelText: '名前',
                    validator: (value) =>
                    value == null || value.isEmpty ? '名前を入力してください' : null,
                  ),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 4),
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
                          Text(
                            _selectedDate == null
                                ? '入社日を選択してください'
                                : '入社日: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                            style: TextStyle(color: Colors.grey.shade800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text('管理者権限を付与する'),
                    value: _isAdmin,
                    onChanged: (val) {
                      setState(() {
                        _isAdmin = val ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'ユーザーを追加する',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 60),

            Text('ユーザー編集／削除', style: TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            Form(
              key: _editFormKey,
              child: Column(
                children: [
                  _buildShadowInput(
                    controller: _editUsernameController,
                    labelText: '変更／削除対象のユーザーID',
                    validator: (value) =>
                    value == null || value.isEmpty ? 'ユーザーIDを入力してください' : null,
                  ),
                  _buildShadowInput(
                    controller: _editPasswordController,
                    labelText: '新しいパスワード（変更時のみ）',
                    obscure: true,
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isEditting
                              ? null
                              : () async {
                            if (!_editFormKey.currentState!.validate()) return;

                            if (_editPasswordController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('ユーザーIDと新しいパスワードを入力してください')),
                              );
                              return;
                            }

                            setState(() {
                              _isEditting = true;
                            });

                            try {
                              final success = await ApiService.changePassword(
                                _editUsernameController.text.trim(),
                                _editPasswordController.text.trim(),
                              );
                              if (success == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('パスワードを変更しました。')),
                                );
                                _editPasswordController.clear();
                                await _fetchAllUsers();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('パスワードの変更に失敗しました。')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('変更失敗: $e')),
                              );
                            } finally {
                              setState(() {
                                _isEditting = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A), // 네이비 블루
                            foregroundColor: Colors.white, // 텍스트 색상
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isEditting
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Text(
                            'パスワード変更',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isEditting
                              ? null
                              : () async {
                            if (!_editFormKey.currentState!.validate()) return;

                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('確認'),
                                content: Text('${_editUsernameController.text.trim()} を削除してもよろしいですか？'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(false),
                                    child: const Text('キャンセル'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(true),
                                    child: const Text('削除'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm != true) return;

                            setState(() {
                              _isEditting = true;
                            });

                            try {
                              final success = await ApiService.deleteUser(
                                _editUsernameController.text.trim(),
                              );
                              if (success == true) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ユーザーを削除しました。')),
                                );
                                _editUsernameController.clear();
                                _editPasswordController.clear();
                                await _fetchAllUsers();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('ユーザーの削除に失敗しました。')),
                                );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('削除失敗: $e')),
                              );
                            } finally {
                              setState(() {
                                _isEditting = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFDC2626), // 따뜻한 레드
                            foregroundColor: Colors.white, // 텍스트 색상
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isEditting
                              ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Text(
                            'ユーザー削除',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),

            const SizedBox(height: 40),

            // --- 사용자 리스트 ---
            const Text('登録済みユーザー一覧'),
            const SizedBox(height: 8),
            _isLoadingUsers
                ? const Center(child: CircularProgressIndicator())
                : _allUsers.isEmpty
                ? const Text('ユーザーが見つかりません')
                : Column(
              children: _allUsers.map((user) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${user['username']} (${user['name']})'),
                      Text(
                        user['isAdmin'] == true ? '管理者' : '一般',
                        style: TextStyle(
                          color: user['isAdmin'] == true ? Colors.red : Colors.black,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
