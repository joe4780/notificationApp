import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'post.dart';

class UserScreen extends StatefulWidget {
  final int userId;

  const UserScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserScreen> createState() => _UserScreenState();
}

class _UserScreenState extends State<UserScreen> {
  List<Map<String, dynamic>> _notifications = [];
  final ApiService apiService = ApiService('http://localhost:3000');
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final notificationsData =
          await apiService.fetchUserNotifications(widget.userId);

      print('Fetched notifications data: $notificationsData'); // Debugging

      // Ensure the data is a list of maps
      if (notificationsData is List) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(notificationsData);
        });
      } else {
        throw Exception('Unexpected data format');
      }
    } catch (e) {
      print('Error during notifications fetch: $e'); // Debugging
      setState(() {
        _error = 'Error fetching notifications: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await apiService.markNotificationAsRead(notificationId);
      await _fetchNotifications(); // Refresh the list after marking as read
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notification as read: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Notifications'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _notifications.isEmpty
                    ? const Center(child: Text('No notifications available'))
                    : ListView.builder(
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final notification = _notifications[index];
                          final isRead = notification['is_read'] == 1;
                          final timestamp = notification['sent_at'] != null
                              ? DateFormat('yyyy-MM-dd HH:mm:ss').format(
                                  DateTime.parse(notification['sent_at']))
                              : 'Unknown';

                          return Dismissible(
                            key: Key(notification['id'].toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child:
                                  const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (direction) {
                              // Implement delete functionality here
                              // For now, we'll just remove it from the list
                              setState(() {
                                _notifications.removeAt(index);
                              });
                            },
                            child: ListTile(
                              title: Text(
                                notification['message'],
                                style: TextStyle(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Text('Sent at: $timestamp'),
                              trailing: isRead
                                  ? const Icon(Icons.check, color: Colors.green)
                                  : IconButton(
                                      icon: const Icon(
                                          Icons.check_box_outline_blank,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _markAsRead(notification['id']),
                                    ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
