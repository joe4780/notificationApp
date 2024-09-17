import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  Set<int> _selectedUserIds = {};
  bool _isLoading = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
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
      print('Raw response: ${response.body}'); // Debugging line
      if (response.statusCode == 200) {
        final List<dynamic> userList = jsonDecode(response.body);
        setState(() {
          _users =
              userList.map((user) => user as Map<String, dynamic>).toList();
        });
      } else {
        print('Failed to load users. Status code: ${response.statusCode}');
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
        } else {
          print(
              'Failed to send notification. Status code: ${response.statusCode}');
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _notificationFormKey,
          child: Column(
            children: [
              TextFormField(
                controller: _messageController,
                decoration:
                    const InputDecoration(labelText: 'Notification Message'),
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
                    labelText: 'Expiry Date (YYYY-MM-DD)'),
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
                Expanded(
                  child: ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      final userId = user['id'] as int?;
                      final userName = user['name'] as String?;
                      final isSelected =
                          userId != null && _selectedUserIds.contains(userId);
                      return CheckboxListTile(
                        title: Text(userName ?? 'Unknown User'),
                        value: isSelected,
                        onChanged: userId == null
                            ? null
                            : (bool? value) {
                                setState(() {
                                  if (value == true) {
                                    _selectedUserIds.add(userId);
                                  } else {
                                    _selectedUserIds.remove(userId);
                                  }
                                });
                              },
                      );
                    },
                  ),
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
      ),
    );
  }
}
