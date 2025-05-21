import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> logout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('로그아웃'),
      content: const Text('정말 로그아웃하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('로그아웃'),
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
