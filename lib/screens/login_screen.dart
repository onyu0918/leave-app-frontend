import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _attemptAutoLogin();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _attemptAutoLogin() async {
    final isValid = await ApiService.validateToken();

    if (isValid) {
      final isAdminString = await StorageService.read('isAdmin');
      final isAdmin = isAdminString == 'true';

      if (!mounted) return;

      Navigator.pushReplacementNamed(
        context,
        isAdmin ? '/admin' : '/user',
      );
    } else {
      await StorageService.delete('token');
      await StorageService.delete('isAdmin');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog("ユーザーIDとパスワードをすべて入力してください。");
      return;
    }

    try {
      final response = await ApiService.login(username, password);
      final token = response['token'];
      final isAdmin = response['isAdmin'];

      await StorageService.write('token', token);
      await StorageService.write('isAdmin', isAdmin.toString());

      if (isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin');
      } else {
        Navigator.pushReplacementNamed(context, '/user');
      }
    } catch (e) {
      _showErrorDialog("ユーザーIDまたはパスワードが正しくありません。");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("ログインに失敗しました。"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("確認"),
          ),
        ],
      ),
    );
  }

  Widget _buildShadowInput({required TextEditingController controller, required String labelText, bool obscure = false, void Function(String)? onSubmitted}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
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
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: const TextStyle(color: Colors.grey),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        autofillHints: obscure ? [AutofillHints.password] : [AutofillHints.username],
        textInputAction: obscure ? TextInputAction.done : TextInputAction.next,
        onSubmitted: onSubmitted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade700),
              const SizedBox(height: 16),
              Text(
                "ログイン",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 32),

              _buildShadowInput(
                controller: _usernameController,
                labelText: "ユーザーID",
              ),

              _buildShadowInput(
                controller: _passwordController,
                labelText: "パスワード",
                obscure: true,
                onSubmitted: (_) => _handleLogin(),
              ),

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
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "ログイン",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
