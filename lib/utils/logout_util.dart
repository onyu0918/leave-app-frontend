import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> logout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('ログアウト'),
      content: const Text('本当にログアウトしてもよろしいですか？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('取り消し'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('ログアウト'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    const storage = FlutterSecureStorage();
    await storage.deleteAll();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }
}
