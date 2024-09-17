import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _notificationFormKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _expiryDateController = TextEditingController();
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _notifications = [];
  Set<int> _selectedUserIds = {};
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchNotifications();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/users'));
      if (response.statusCode == 200) {
        final List<dynamic> userList = jsonDecode(response.body);
        setState(() {
          _users =
              userList.map((user) => user as Map<String, dynamic>).toList();
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching users: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3000/notifications'));
      if (response.statusCode == 200) {
        final List<dynamic> notificationsList = jsonDecode(response.body);
        setState(() {
          _notifications = notificationsList
              .map((notification) => notification as Map<String, dynamic>)
              .toList();
        });
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching notifications: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendNotification() async {
    if (_notificationFormKey.currentState?.validate() ?? false) {
      setState(() {
        _isSending = true;
      });
      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/notifications'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': _messageController.text,
            'userIds': _selectedUserIds.toList(),
            'expiry_date': _expiryDateController.text,
          }),
        );
        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notification sent successfully!')),
            );
          }
          _messageController.clear();
          _expiryDateController.clear();
          setState(() {
            _selectedUserIds.clear();
          });
          _fetchNotifications(); // Refresh the notifications list
        } else {
          throw Exception('Failed to send notification');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending notification: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSending = false;
          });
        }
      }
    }
  }

  bool _isValidDate(String date) {
    try {
      DateTime.parse(date);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchUsers();
              _fetchNotifications();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _notificationFormKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Notification Message',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a message';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _expiryDateController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date (YYYY-MM-DD)',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an expiry date';
                      }
                      if (!_isValidDate(value)) {
                        return 'Please enter a valid date in YYYY-MM-DD format';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading)
                    const CircularProgressIndicator()
                  else if (_users.isNotEmpty)
                    Wrap(
                      spacing: 8.0,
                      children: _users.map((user) {
                        final userId = user['id'] as int?;
                        final userName = user['username'] as String?;
                        final isSelected =
                            userId != null && _selectedUserIds.contains(userId);
                        return FilterChip(
                          label: Text(userName ?? 'Unknown User'),
                          selected: isSelected,
                          onSelected: userId == null
                              ? null
                              : (bool selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedUserIds.add(userId);
                                    } else {
                                      _selectedUserIds.remove(userId);
                                    }
                                  });
                                },
                        );
                      }).toList(),
                    )
                  else
                    const Text('No users found'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _isSending ? null : _sendNotification,
                    child: _isSending
                        ? const CircularProgressIndicator()
                        : const Text('Send Notification'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _notifications.isEmpty
                      ? const Center(child: Text('No notifications found'))
                      : ListView.builder(
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            final isRead = notification['is_read'] == 1;
                            final sentAt = notification['sent_at'] != null
                                ? DateFormat('yyyy-MM-dd HH:mm').format(
                                    DateTime.parse(notification['sent_at']))
                                : 'Unknown';
                            final userId = notification['user_id'];
                            final user = _users.firstWhere(
                                (u) => u['id'] == userId,
                                orElse: () => {'username': 'Unknown User'});

                            return ListTile(
                              title:
                                  Text(notification['message'] ?? 'No message'),
                              subtitle: Text(
                                  'Sent to: ${user['username']} on $sentAt'),
                              trailing: Icon(
                                isRead
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: isRead ? Colors.green : Colors.red,
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
