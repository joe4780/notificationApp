import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:notification_app/api/api_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
      final response = await http.get(
        Uri.parse('${apiService.baseUrl}/users/${widget.userId}/notifications'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> decodedData = json.decode(response.body);
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(decodedData);
        });
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      setState(() {
        _error = 'Network error: $e';
      });
    } catch (e) {
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
      setState(() {
        final index =
            _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notification as read: $e')),
      );
    }
  }

  void _openNotificationDetails(Map<String, dynamic> notification) async {
    if (notification['is_read'] != true) {
      await _markAsRead(notification['id']);
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Notification Details'),
          content: Text(notification['message']),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Notifications'),
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
                          final isRead = notification['is_read'] == true;
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
                                  ? null
                                  : const Icon(Icons.circle,
                                      color: Colors.blue, size: 12),
                              onTap: () =>
                                  _openNotificationDetails(notification),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
