import '../services/api_service.dart';
import 'package:intl/intl.dart';

class LeaveService {
  Future<Map<String, dynamic>> fetchLeaveData() async {
    try {
      final userResponse = await ApiService.getCurrentUser();
      final data = userResponse['data'];
      if (data == null || data['joinDate'] == null) {
        throw Exception('入社日情報がありません。');
      }

      final joinDate = DateTime.parse(data['joinDate']);
      // final today = DateTime.now();
      final today = await ApiService.getSysdate();

      final resetDate = _getResetDate(today, joinDate);
      final leaves = await ApiService.getUserLeaves();
      final holidayList = await ApiService.getHolidays();
      final Set<String> holidaySet = holidayList
          .map((h) => DateFormat('yyyyMMdd').format(DateTime.parse(h['holidayDate'])))
          .toSet();

      double usedDays = 0.0;
      double pendingLeaves = 0.0;
      double approvedLeaves = 0.0;

      for (var leave in leaves) {
        final status = leave['status'];
        final start = DateTime.parse(leave['startDate']);
        final end = DateTime.parse(leave['endDate']);
        final days = leave['days'];

        if (end.isBefore(resetDate)) continue;

        final effectiveStart = start.isBefore(resetDate) ? resetDate : start;
        final businessDays = _countBusinessDays(effectiveStart, end, holidaySet);

        final usedDaysValue = (days != null && days < 1) ? days : businessDays;

        if (status != 2) {
          usedDays += usedDaysValue;
        }

        if (status == 0) {
          pendingLeaves += usedDaysValue;
        }

        if (status == 1) {
          approvedLeaves += usedDaysValue;
        }
      }
      final totalLeaves = _calculateLeaves(joinDate, today);

      return {
        'availableLeaves': totalLeaves - usedDays,
        'usedLeaves': usedDays,
        'pendingLeaves': pendingLeaves,
        'approvedLeaves': approvedLeaves,
        'username': data['username'],
        'name': data['name'],
      };
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> userLeaveData(String username) async {
    try {
      final userResponse = await ApiService.getUser(username);
      final data = userResponse['data'];
      if (data == null || data['joinDate'] == null) {
        throw Exception('入社日情報がありません。');
      }

      final joinDate = DateTime.parse(data['joinDate']);
      final today = DateTime.now();

      final resetDate = _getResetDate(today, joinDate);
      final leaves = await ApiService.getLeaves(username);
      final holidayList = await ApiService.getHolidays();
      final Set<String> holidaySet = holidayList
          .map((h) => DateFormat('yyyyMMdd').format(DateTime.parse(h['holidayDate'])))
          .toSet();

      double usedDays = 0;
      for (var leave in leaves) {
        if (leave['status'] != 1) continue;

        final start = DateTime.parse(leave['startDate']);
        final end = DateTime.parse(leave['endDate']);

        if (end.isBefore(resetDate)) continue;

        final effectiveStart = start.isBefore(resetDate) ? resetDate : start;

        final leaveDays = leave['days'];
        if (leaveDays != null && leaveDays < 1) {
          usedDays += leaveDays;
        } else {
          usedDays += _countBusinessDays(effectiveStart, end, holidaySet);
        }
      }

      final totalLeaves = _calculateLeaves(joinDate, today);

      return {
        'availableLeaves': totalLeaves - usedDays,
        'usedLeaves': usedDays,
        'username': data['username'],
        'name': data['name'],
        'days': data['days'],
      };
    } catch (e) {
      rethrow;
    }
  }
  // DateTime _getResetDate(DateTime today, DateTime joinDate) {
  //   DateTime resetDate = DateTime(today.year, joinDate.month, joinDate.day);
  //   if (today.isBefore(resetDate)) {
  //     resetDate = DateTime(today.year - 1, joinDate.month, joinDate.day);
  //   }
  //   return resetDate;
  // }
  //
  //
  // int _calculateLeaves(DateTime joinDate, DateTime today) {
  //   if (today.isBefore(joinDate)) return 0;
  //
  //   final resetDate = _getResetDate(today, joinDate);
  //   final yearsSinceJoin = resetDate.year - joinDate.year;
  //   int monthsSinceReset = (today.year - resetDate.year) * 12 + (today.month - resetDate.month);
  //   if (today.day < joinDate.day) monthsSinceReset--;
  //
  //   if (joinDate.year == resetDate.year) {
  //     int monthsWorked = (today.year - joinDate.year) * 12 + (today.month - joinDate.month);
  //     if (today.day < joinDate.day) monthsWorked--;
  //     return monthsWorked.clamp(0, 9) + 1;
  //   }
  //
  //   int total = 0;
  //   switch (yearsSinceJoin) {
  //     case 1:
  //       total = monthsSinceReset.clamp(0, 10) + 1;
  //       break;
  //     case 2:
  //       total += (monthsSinceReset >= 0 ? 2 : 0);
  //       total += (monthsSinceReset >= 1 ? 2 : 0);
  //       total += (monthsSinceReset - 2).clamp(0, 10);
  //       total = total.clamp(0, 12);
  //       break;
  //     case 3:
  //       total += (monthsSinceReset >= 0 ? 2 : 0);
  //       total += (monthsSinceReset >= 1 ? 2 : 0);
  //       total += (monthsSinceReset >= 2 ? 2 : 0);
  //       total += (monthsSinceReset - 3).clamp(0, 10);
  //       total = total.clamp(0, 13);
  //       break;
  //     case 4:
  //       total += (monthsSinceReset >= 0 ? 2 : 0);
  //       total += (monthsSinceReset >= 1 ? 2 : 0);
  //       total += (monthsSinceReset >= 2 ? 2 : 0);
  //       total += (monthsSinceReset >= 3 ? 2 : 0);
  //       total += (monthsSinceReset - 4).clamp(0, 10);
  //       total = total.clamp(0, 14);
  //       break;
  //     default:
  //       total = 999;
  //   }
  //
  //   return total;
  // }


  DateTime _addOneMonth(DateTime date) {
    final year = date.year;
    final month = date.month + 1;
    final day = date.day;

    final nextMonthDate = DateTime(year, month, 1);
    final lastDayOfNextMonth = DateTime(nextMonthDate.year, nextMonthDate.month + 1, 0).day;
    return DateTime(nextMonthDate.year, nextMonthDate.month, day.clamp(1, lastDayOfNextMonth));
  }

  DateTime _getResetDate(DateTime today, DateTime joinDate) {
    DateTime resetDate = DateTime(today.year, joinDate.month, joinDate.day);
    if (today.isBefore(resetDate)) {
      resetDate = DateTime(today.year - 1, joinDate.month, joinDate.day);
    }
    return resetDate;
  }

  int _calculateLeaves(DateTime joinDate, DateTime today) {
    if (today.isBefore(joinDate)) return 0;

    final resetDate = _getResetDate(today, joinDate);
    final accrualStartDate = _addOneMonth(resetDate);

    if (today.isBefore(accrualStartDate)) return 0;

    final yearsSinceJoin = resetDate.year - joinDate.year;

    int monthsSinceReset = (today.year - resetDate.year) * 12 + (today.month - resetDate.month);
    if (today.day <= resetDate.day) monthsSinceReset--;

    if (joinDate.year == resetDate.year) {
      int monthsWorked = (today.year - accrualStartDate.year) * 12 + (today.month - accrualStartDate.month);
      if (today.day < accrualStartDate.day) monthsWorked--;
      return (monthsWorked + 1).clamp(0, 10);
    }
    print('monthsSinceReset: $monthsSinceReset');
    print('total leaves: ${(monthsSinceReset + 1).clamp(0, 11)}');
      int total = 0;
      switch (yearsSinceJoin) {
        case 1:
          total = (monthsSinceReset + 1).clamp(0, 11);
          break;
        case 2:
          total = (monthsSinceReset + 1).clamp(0, 12);
          break;
        case 3:
          total += (monthsSinceReset >= 0 ? 2 : 0);
          total += monthsSinceReset.clamp(0, 11);
          total = total.clamp(0, 13);
          break;
        case 4:
          total += (monthsSinceReset >= 0 ? 2 : 0);
          total += (monthsSinceReset >= 1 ? 2 : 0);
          total += (monthsSinceReset - 1).clamp(0, 10);
          total = total.clamp(0, 14);
          break;
        default:
          total = 999;
    }

    return total;
  }








  int _countBusinessDays(DateTime from, DateTime to, Set<String> holidaySet) {
    int count = 0;
    DateFormat formatter = DateFormat('yyyyMMdd');

    DateTime current = from;
    while (!current.isAfter(to)) {
      bool isWeekend = current.weekday == DateTime.saturday || current.weekday == DateTime.sunday;
      bool isHoliday = holidaySet.contains(formatter.format(current));

      if (!isWeekend && !isHoliday) {
        count++;
      }

      current = current.add(Duration(days: 1));
    }

    return count;
  }

  Future<int> calculateWorkingDays(DateTime start, DateTime end) async {
    final holidayList = await ApiService.getHolidays();
    final Set<String> holidaySet = holidayList
        .map((h) => DateFormat('yyyyMMdd').format(DateTime.parse(h['holidayDate'])))
        .toSet();
    return _countBusinessDays(start, end, holidaySet);
  }
}
