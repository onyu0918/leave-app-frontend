import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../services/storage_service.dart';

class ApiService {
  // static const String baseUrl = '10.0.2.2:8080';
  static const String baseUrl = 'localhost:8080';

  static Future<Map<String, dynamic>> login(String username, String password) async {
    final url = Uri.parse('http://$baseUrl/api/auth/login');

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

  static Future<Map<String, dynamic>> applyLeave(String startDate, String endDate, String reason) async {
    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';

    if (token == null) {
      throw Exception('로그인이 필요합니다.');
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
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('연차 신청 실패 (상태코드: ${response.statusCode})');
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
      throw Exception('삭제 실패: ${response.body}');
    }
  }

  static Future<List<Map<String, dynamic>>> getUserLeaves() async {

    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';

    if (token == null) {
      throw Exception('로그인이 필요합니다.');
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
      throw Exception('연차 내역 조회 실패 (상태코드: ${response.statusCode})');
    }
  }


  static Future<List<Map<String, dynamic>>> getAllLeaveRequests() async {
    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';

    final url = Uri.parse('http://$baseUrl/api/leave/admin/leave-requests');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('전체 연차 신청 목록 조회에 실패했습니다.');
    }
  }

  static Future<List<dynamic>> getFilteredLeaveRequests({
    required int page,
    required int size,
    String? status,
    String? name,
    int? months,
  }) async {
    developer.log('Type of name: ${name}');
    final Map<String, String> queryParams = {
      'page': page.toString(),
      'size': size.toString(),
      if (status != null) 'status': status,
      if (name != null && name.isNotEmpty) 'username': name,
      if (months != null) 'months': months.toString(),
    };
    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';

    final uri = Uri.http(baseUrl, '/api/leave/admin/leave-requests', queryParams);

    final response = await http.get(uri, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> content = data['content'];
      return content;
    } else {
      throw Exception('Failed to load filtered leave requests: ${response.body}');
    }
  }


  static Future<void> updateLeaveStatus(
      int leaveId,
      String status, {
        String? rejectReason,
      }) async {
    final url = Uri.parse('http://$baseUrl/api/leave/admin/$leaveId/status');

    final body = {
      'status': status,
    };

    if (rejectReason != null && rejectReason.isNotEmpty) {
      body['rejectReason'] = rejectReason;
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
      throw Exception('Failed to update leave status');
    }
  }

  static Future<Map<String, dynamic>> addUser({
    required String username,
    required String password,
    required bool isAdmin,
    required String joinDate,
  }) async {
    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';


    if (token == null) {
      throw Exception('로그인이 필요합니다.');
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
        'isAdmin': isAdmin.toString(),
        'joinDate': joinDate,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('유저 추가 실패: ${response.statusCode} - ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getCurrentUser() async {
    final token = await StorageService.read('token');
    final isAdminString = await StorageService.read('isAdmin');
    final isAdmin = isAdminString == 'true';

    if (token == null) {
      throw Exception('로그인이 필요합니다.');
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
      throw Exception('현재 사용자 정보 조회 실패: ${response.statusCode} - ${response.body}');
    }
  }

}
