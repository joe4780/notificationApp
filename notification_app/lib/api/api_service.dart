import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'https://gratis-pear-stew.glitch.me';

  Future<List<Map<String, dynamic>>> fetchUserNotifications(int userId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/notifications/user/$userId'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    final response = await http
        .put(Uri.parse('$baseUrl/notifications/$notificationId/read'));

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notification as read');
    }
  }
}
