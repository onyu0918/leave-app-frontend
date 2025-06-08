import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../services/storage_service.dart';

class ApiService {
  // static const String baseUrl = 'localhost:8080';
  static const String baseUrl = '126.227.152.197:8080';

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('http://$baseUrl/api/auth/login');
    print('Calling URL: http://$baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('LOGIN FAILED: ${response.statusCode}');
    }
  }

  static Future<bool> deleteUser(String username) async {
    final url = Uri.parse('http://$baseUrl/api/users/user/$username');

    final token = await StorageService.read('token');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      developer.log('User deleted successfully');
      return true;
    } else {
      developer.log('Failed to delete user: ${response.statusCode}');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    final token = await StorageService.read('token');

    if (token == null) {
      throw Exception('ログインが必要です。');
    }

    final url = Uri.parse('http://$baseUrl/api/users/all');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      if (jsonResponse['success'] == true) {
        final List<dynamic> users = jsonResponse['data'];

        return users.map<Map<String, dynamic>>((user) => Map<String, dynamic>.from(user)).toList();
      } else {
        throw Exception('ユーザー情報の取得に失敗しました: ${jsonResponse['message']}');
      }
    } else if (response.statusCode == 403) {
      throw Exception('権限がありません。管理者のみ操作可能です。');
    } else {
      throw Exception('サーバーエラー: ${response.statusCode}');
    }
  }

  static Future<bool> validateToken() async {
    final token = await StorageService.read('token');
    if (token == null) return false;

    final url = Uri.parse('http://$baseUrl/api/auth/validate');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    return response.statusCode == 200;
  }

  static Future<int> getPendingLeaveCount() async {
    final token = await StorageService.read('token');

    if (token == null) {
      throw Exception('ログインが必要となります。');
    }

    final url = Uri.parse('http://$baseUrl/api/leave/count/pending');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['count'] ?? 0;
    } else {
      throw Exception('保留中の申請数の取得に失敗しました（ステータスコード: ${response.statusCode})');
    }
  }


  static Future<void> applyLeave(String startDate, String endDate, String reason, double days) async {
    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';

    if (token == null) {
      throw Exception('ログインが必要です。');
    }

    final url = Uri.parse('http://$baseUrl/api/leave/apply');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'startDate': startDate,
        'endDate': endDate,
        'reason': reason,
        'days': days,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('有給休暇申請失敗（ステータスコード: ${response.statusCode})');
    }
  }

  static Future<void> deleteLeave(int id) async {
    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';

    final url = Uri.parse('http://$baseUrl/api/leave/delete/$id');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('削除に失敗いたしました: ${response.body}');
    }
  }

  static Future<void> adminDeleteLeave(int id) async {
    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';

    final url = Uri.parse('http://$baseUrl/api/leave/admin/delete/$id');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('削除に失敗いたしました: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserLeaves() async {

    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';

    if (token == null) {
      throw Exception('ログインが必要となります。');
    }

    final url = Uri.parse('http://$baseUrl/api/leave/list');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('有給休暇履歴の取得に失敗しました（ステータスコード: ${response.statusCode})');
    }
  }

  static Future<List<Map<String, dynamic>>> getLeaves(String username) async {

    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';

    if (token == null) {
      throw Exception('ログインが必要となります。');
    }

    final url = Uri.parse('http://$baseUrl/api/leave/lists/$username');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('有給休暇履歴の取得に失敗しました（ステータスコード: ${response.statusCode})');
    }
  }

  static Future<Map<DateTime, List<String>>> getAllLeaveRequests() async {
    final token = await StorageService.read('token');
    final url = Uri.parse('http://$baseUrl/api/leave/admin/allleave-requests');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final Map<DateTime, List<String>> result = {};

      data.forEach((key, value) {
        final date = DateTime.parse(key);
        result[DateTime.utc(date.year, date.month, date.day)] =
        List<String>.from(value);
      });

      return result;
    } else {
      throw Exception('有給休暇カレンダーデータの読み込みに失敗しました。');
    }
  }

  static Future<DateTime> getSysdate() async {
    final token = await StorageService.read('token');
    final url = Uri.parse('http://$baseUrl/api/leave/get-sysdate');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final String data = json.decode(response.body);
      final DateTime result = DateTime.parse(data);

      return result;
    } else {
      throw Exception('有給休暇カレンダーデータの読み込みに失敗しました。');
    }
  }

  static Future<List<Map<String, dynamic>>> getFilteredLeaveRequests({
    required int page,
    required int size,
    int? status,
    String? name,
    int? months,
  }) async {
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      if (status != null) 'status': status.toString(),
      if (name != null && name.isNotEmpty) 'username': name,
      if (months != null) 'months': months.toString(),
    };
    final token = await StorageService.read('token');

    final uri = Uri.http(baseUrl, '/api/leave/admin/leave-requests', queryParams);

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['content'] is List) {
        final List<dynamic> contentList = data['content'];
        return contentList.map<Map<String, dynamic>>((item) {
          if (item is Map) {
            return Map<String, dynamic>.from(item);
          } else {
            throw Exception('コンテンツリストの要素がMapではありません。');
          }
        }).toList();
      } else {
        throw Exception('レスポンスの内容がリストではありません。');
      }
    } else {
      throw Exception('絞り込み済みの休暇申請の読み込みに失敗しました。: ${response.body}');
    }
  }


  static Future<void> updateLeaveStatus(
      int leaveId,
      int status, {
        String? comment,
      }) async {
    final url = Uri.parse('http://$baseUrl/api/leave/admin/$leaveId/status');

    final Map<String, dynamic> body = {
      'status': status,
    };

    if (comment != null && comment.isNotEmpty) {
      body['comment'] = comment;
    }

    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';


    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('休暇の状態更新に失敗しました。');
    }
  }

  static Future<void> updateUserLeaveStatus(
      int leaveId,
      int status) async {
    final url = Uri.parse('http://$baseUrl/api/leave/$leaveId/status');

    final Map<String, dynamic> body = {
      'status': status,
    };

    final token = await StorageService.read('token');

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('休暇の状態更新に失敗しました。');
    }
  }

  static Future<Map<String, dynamic>> addUser({
    required String username,
    required String password,
    required String name,
    required bool isAdmin,
    required String joinDate,
  }) async {
    final token = await StorageService.read('token');

    if (token == null) {
      throw Exception('ログインが必要となります。');
    }

    final url = Uri.parse('http://$baseUrl/api/users/add');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer $token',
      },
      body: {
        'username': username,
        'password': password,
        'name': name,
        'isAdmin': isAdmin.toString(),
        'joinDate': joinDate,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('ユーザーの追加に失敗しました。: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';

    if (token == null) {
      throw Exception('ログインが必要となります。');
    }

    final url = Uri.parse('http://$baseUrl/api/users/me');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('現在のユーザー情報の取得に失敗しました。: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getUser(String username) async {
    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';

    if (token == null) {
      throw Exception('ログインが必要となります。');
    }

    final url = Uri.parse('http://$baseUrl/api/users/user/$username');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('現在のユーザー情報の取得に失敗しました。: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getHolidays() async {
    final token = await StorageService.read('token');

    if (token == null) {
      throw Exception('ログインが必要となります。');
    }

    final url = Uri.parse('http://$baseUrl/api/holidays');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('祝日リストの取得に失敗しました（ステータスコード: ${response.statusCode})');
    }
  }

  static Future<bool> resetPassword(String username) async {
    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';

    if (token == null || !isAdmin) {
      throw Exception('管理者権限が必要です。');
    }

    final url = Uri.parse('http://$baseUrl/api/reset-password/$username');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['success'] == true) {
        return true;
      } else {
        throw Exception(data['message'] ?? 'パスワード初期化に失敗しました。');
      }
    } else {
      throw Exception('パスワード初期化リクエスト失敗 (status: ${response.statusCode})');
    }
  }

  static Future<bool> changePassword(String username, String newPassword) async {
    final token = await StorageService.read('token');
    if (token == null) {
      throw Exception('ログインが必要です。');
    }

    final url = Uri.parse('http://$baseUrl/api/users/change-password');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': username,
        'newPassword': newPassword,
      },
    );

    if (response.statusCode == 200) {
      return true;
    } else if (response.statusCode == 400) {
      throw Exception('現在のパスワードが正しくありません。');
    } else if (response.statusCode == 401) {
      throw Exception('認証に失敗しました。');
    } else {
      throw Exception('パスワード変更に失敗しました。ステータスコード: ${response.statusCode}');
    }
  }
}
