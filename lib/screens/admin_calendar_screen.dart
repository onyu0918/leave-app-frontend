import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';

class AdminCalendarScreen extends StatefulWidget {
  const AdminCalendarScreen({super.key});

  @override
  State<AdminCalendarScreen> createState() => _AdminCalendarScreenState();
}

class _AdminCalendarScreenState extends State<AdminCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _leaveEvents = {};
  CalendarFormat _calendarFormat = CalendarFormat.month;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchLeaves();
  }

  Future<void> _fetchLeaves() async {
    try {
      final response = await ApiService.getAllLeaveRequests();
      final Map<DateTime, List<String>> eventMap = {};
      for (var entry in response.entries) {
        final date = entry.key;
        final names = entry.value;
        eventMap.putIfAbsent(date, () => []).addAll(names);
      }
      setState(() {
        _leaveEvents = eventMap;
      });
    } catch (e) {
      print('休暇データの取得中にエラーが発生しました: $e');
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime.utc(day.year, day.month, day.day);
    final events = _leaveEvents[normalizedDate] ?? [];
    if (_searchQuery.isEmpty) return events;
    return events
        .where((name) => name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('休暇カレンダー')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'ユーザー名で検索',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedDay != null)
            Expanded(
              child: ListView(
                children: _getEventsForDay(_selectedDay!).map((name) {
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(name),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
