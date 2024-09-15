import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl;

  ApiService(this.baseUrl);

  // Method to send notifications from the admin to users
  Future<dynamic> sendNotification(
      String message, List<int> userIds, String expiryDate) async {
    final url = Uri.parse('$baseUrl/notifications');
    try {
      // Send POST request to the server with notification data
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': message,
          'userIds': userIds,
          'expiry_date': expiryDate,
        }),
      );

      // Check if the request was successful
      if (response.statusCode == 201) {
        // Successfully sent the notification
        return jsonDecode(response.body);
      } else {
        // Handle error
        return {
          'error': 'Failed to send notification: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Handle network or JSON errors
      return {
        'error': 'Error sending notification: $e',
      };
    }
  }

  // Fetch all users from the database (for user selection in the admin panel)
  Future<List<dynamic>> fetchUsers() async {
    final url = Uri.parse('$baseUrl/users');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Fetch notifications for admin to display
  Future<List<dynamic>> fetchNotifications() async {
    final url = Uri.parse('$baseUrl/notifications');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }
}
