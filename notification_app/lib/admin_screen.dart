import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

// Controller to manage Admin operations using GetX
class AdminController extends GetxController {
  final isLoading = false.obs;
  final isSending = false.obs;
  final messageController = TextEditingController();
  final expiryDateController = TextEditingController();
  final selectedUserIds = <int>{}.obs;
  final selectedUsernames = <String>[].obs;
  final users = <Map<String, dynamic>>[].obs;
  final notifications = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchUsers();
    fetchNotifications();
  }

  // Fetch users from API
  Future<void> fetchUsers() async {
    isLoading.value = true;
    try {
      final response =
          await http.get(Uri.parse('http://192.168.100.83:3000/users'));
      if (response.statusCode == 200) {
        final userList = jsonDecode(response.body) as List<dynamic>;
        users.value =
            userList.map((user) => user as Map<String, dynamic>).toList();
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error fetching users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch notifications from API
  Future<void> fetchNotifications() async {
    isLoading.value = true;
    try {
      final response =
          await http.get(Uri.parse('http://192.168.100.83:3000/notifications'));
      if (response.statusCode == 200) {
        final notificationsList = jsonDecode(response.body) as List<dynamic>;
        notifications.value = notificationsList
            .map((notification) => notification as Map<String, dynamic>)
            .toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Send notification to selected users
  Future<void> sendNotification() async {
    if (messageController.text.isEmpty || expiryDateController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields');
      return;
    }

    isSending.value = true;
    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.83:3000/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': messageController.text.trim(),
          'userIds': selectedUserIds.toList(),
          'expiry_date': expiryDateController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        Get.snackbar('Success', 'Notification sent successfully!');
        messageController.clear();
        expiryDateController.clear();
        selectedUserIds.clear();
        selectedUsernames.clear();
        fetchNotifications();
      } else {
        throw Exception('Failed to send notification');
      }
    } catch (e) {
      Get.snackbar('Error', 'Error sending notification: $e');
    } finally {
      isSending.value = false;
    }
  }
}

// AdminScreen using GetX
class AdminScreen extends StatelessWidget {
  final AdminController controller = Get.put(AdminController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              controller.fetchUsers();
              controller.fetchNotifications();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              child: Column(
                children: [
                  TextFormField(
                    controller: controller.messageController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Message',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.expiryDateController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.to(UserSelectionScreen()),
                    child: const Text('Select Users'),
                  ),
                  const SizedBox(height: 16),
                  Obx(() => Wrap(
                        spacing: 8.0,
                        children: controller.selectedUsernames
                            .map((username) => Chip(label: Text(username)))
                            .toList(),
                      )),
                  const SizedBox(height: 16),
                  Obx(() => controller.isSending.value
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: controller.sendNotification,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text('Send Notification',
                                style: TextStyle(fontSize: 18)),
                          ),
                        )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Obx(() => controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : controller.notifications.isEmpty
                      ? const Center(child: Text('No notifications found'))
                      : ListView.builder(
                          itemCount: controller.notifications.length,
                          itemBuilder: (context, index) {
                            final notification =
                                controller.notifications[index];
                            final isRead = notification['is_read'] == 1;
                            final sentAt = notification['sent_at'] != null
                                ? DateFormat('yyyy-MM-dd HH:mm').format(
                                    DateTime.parse(notification['sent_at']))
                                : 'Unknown';
                            final userId = notification['user_id'];
                            final user = controller.users.firstWhere(
                                (u) => u['id'] == userId,
                                orElse: () => {'username': 'Unknown User'});

                            return ListTile(
                              title:
                                  Text(notification['message'] ?? 'No message'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Sent to: ${user['username']} on $sentAt'),
                                  Text(
                                    isRead ? 'Read' : 'Unread',
                                    style: TextStyle(
                                      color: isRead ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            );
                          },
                        )),
            ),
          ],
        ),
      ),
    );
  }
}

// UserSelectionScreen using GetX
class UserSelectionScreen extends StatelessWidget {
  final AdminController controller = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Users'),
      ),
      body: Obx(() => ListView.builder(
            itemCount: controller.users.length,
            itemBuilder: (context, index) {
              final user = controller.users[index];
              final userId = user['id'] as int;
              final isSelected = controller.selectedUserIds.contains(userId);

              return CheckboxListTile(
                title: Text(user['username']),
                value: isSelected,
                onChanged: (bool? selected) {
                  if (selected ?? false) {
                    controller.selectedUserIds.add(userId);
                    controller.selectedUsernames.add(user['username']);
                  } else {
                    controller.selectedUserIds.remove(userId);
                    controller.selectedUsernames.remove(user['username']);
                  }
                },
              );
            },
          )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.back(),
        child: const Icon(Icons.check),
      ),
    );
  }
}
