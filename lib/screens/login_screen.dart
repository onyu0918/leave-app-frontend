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
      if (!isValid) {
        await StorageService.delete('token');
        await StorageService.delete('isAdmin');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showErrorDialog("아이디와 비밀번호를 모두 입력하세요.");
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
    } catch (e, stacktrace) {
      print('LOGIN FAILED: $e');
      print(stacktrace);
      _showErrorDialog("아이디 또는 비밀번호가 잘못되었습니다.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("로그인 실패"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("LOGIN"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
              textInputAction: TextInputAction.next,
              onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              autofillHints: const [AutofillHints.username],
            ),

            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleLogin(),
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const [AutofillHints.password],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _handleLogin,
              child: const Text("Log in"),
            ),
          ],
        ),
      ),
    );
  }
}
