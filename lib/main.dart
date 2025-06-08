import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/user_home_screen.dart';
import 'screens/admin_leave_list_screen.dart';
import 'screens/adduser_screen.dart';
import 'screens/admin_calendar_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paid Leave App',
      theme: ThemeData(primarySwatch: Colors.grey),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
        '/user': (context) => const UserHomeScreen(),
        '/admin/leave-requests': (context) => const AdminLeaveListScreen(),
        '/admin/add-user': (context) => const AddUserScreen(),
        '/admin/calendar': (context) => const AdminCalendarScreen(),
      },
    );
  }
}
