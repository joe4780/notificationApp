import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:notification_app/api/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class UserScreen extends StatelessWidget {
  final int userId;

  const UserScreen({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(UserController(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notifications'),
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchNotifications,
        child: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          } else if (controller.error.value.isNotEmpty) {
            return Center(child: Text(controller.error.value));
          } else if (controller.notifications.isEmpty) {
            return const Center(child: Text('No notifications available'));
          }

          return ListView.builder(
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              final isRead = notification['is_read'] == true;
              final timestamp = notification['sent_at'] != null
                  ? DateFormat('yyyy-MM-dd HH:mm:ss')
                      .format(DateTime.parse(notification['sent_at']))
                  : 'Unknown';

              return Dismissible(
                key: Key(notification['id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  controller.notifications.removeAt(index);
                },
                child: ListTile(
                  title: Text(
                    notification['message'],
                    style: TextStyle(
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('Sent at: $timestamp'),
                  trailing: isRead
                      ? null
                      : const Icon(Icons.circle, color: Colors.blue, size: 12),
                  onTap: () => controller.openNotificationDetails(notification),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class UserController extends GetxController {
  final int userId;
  var notifications = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var error = ''.obs;
  final ApiService apiService = ApiService();

  UserController(this.userId) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    isLoading.value = true;
    error.value = '';

    try {
      final response = await http.get(
        Uri.parse('${apiService.baseUrl}/users/$userId/notifications'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        notifications.value = List<Map<String, dynamic>>.from(decodedData);
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      error.value = 'Network error: $e';
    } catch (e) {
      error.value = 'Error fetching notifications: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await apiService.markNotificationAsRead(notificationId);
      final index = notifications.indexWhere((n) => n['id'] == notificationId);
      if (index != -1) {
        notifications[index]['is_read'] = true;
      }
    } catch (e) {
      Get.snackbar('Error', 'Error marking notification as read: $e');
    }
  }

  void openNotificationDetails(Map<String, dynamic> notification) async {
    if (notification['is_read'] != true) {
      await markAsRead(notification['id']);
    }

    Get.dialog(
      AlertDialog(
        title: Text('Notification Details'),
        content: Text(notification['message']),
        actions: <Widget>[
          TextButton(
            child: Text('Close'),
            onPressed: () {
              Get.back();
            },
          ),
        ],
      ),
    );
  }
}
