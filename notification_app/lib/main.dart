import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notification App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Admin Notification Panel'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();
  String _message = '';
  List<String> _selectedUsers = [];
  String _expiryDate = '';
  List<String> _users = [];
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers(); // Fetch users for admin to select
    _fetchNotifications(); // Fetch notifications
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('http://localhost:3000/users'));
      if (response.statusCode == 200) {
        setState(() {
          _users = List<String>.from(
              jsonDecode(response.body).map((user) => user['name']));
        });
      } else {
        print('Failed to fetch users: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3000/notifications'));
      if (response.statusCode == 200) {
        setState(() {
          _notifications = jsonDecode(response.body);
        });
      } else {
        print('Failed to fetch notifications: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Future<void> _sendNotification() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        // Fetch user IDs corresponding to selected user names
        final userIdsResponse =
            await http.get(Uri.parse('http://localhost:3000/users'));
        final userIdsData = jsonDecode(userIdsResponse.body) as List<dynamic>;
        final userIdsMap = {
          for (var user in userIdsData) user['name']: user['id']
        };

        final selectedUserIds =
            _selectedUsers.map((userName) => userIdsMap[userName]).toList();

        final response = await http.post(
          Uri.parse('http://localhost:3000/notifications'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'message': _message,
            'userIds': selectedUserIds,
            'expiry_date': _expiryDate,
          }),
        );

        if (response.statusCode == 201) {
          // Notification sent successfully
          _fetchNotifications(); // Refresh the list
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification sent!')),
          );
        } else {
          print('Failed to send notification: ${response.statusCode}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send notification')),
          );
        }
      } catch (e) {
        print('Error sending notification: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send notification')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Admin Panel - Send Notification',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 20),

              // Button to select users
              ElevatedButton(
                onPressed: () async {
                  final selectedUsers = await _showUserSelectionDialog(context);
                  if (selectedUsers != null) {
                    setState(() {
                      _selectedUsers = selectedUsers;
                    });
                  }
                },
                child: const Text('Select Users'),
              ),
              const SizedBox(height: 20),

              // Display selected users count
              Text(
                'Selected Users: ${_selectedUsers.length}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),

              // Admin Form to send notification
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Notification Message'),
                      onSaved: (value) {
                        _message = value!;
                      },
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter a message' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(
                          labelText: 'Expiry Date (optional)'),
                      onSaved: (value) {
                        _expiryDate = value!;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _sendNotification,
                      child: const Text('Send Notification'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Display Notifications
              Text('Notifications',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              _notifications.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return ListTile(
                          title: Text(notification['message']),
                          subtitle: Text('Sent to: ${notification['user_id']}'),
                        );
                      },
                    )
                  : const Text('No notifications available'),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<String>?> _showUserSelectionDialog(BuildContext context) async {
    List<String> selectedUsers = [];
    return showDialog<List<String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Users'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: _users.map((user) {
                  return CheckboxListTile(
                    title: Text(user),
                    value: selectedUsers.contains(user),
                    onChanged: (isChecked) {
                      setState(() {
                        if (isChecked == true) {
                          selectedUsers.add(user);
                        } else {
                          selectedUsers.remove(user);
                        }
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(selectedUsers);
              },
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(null);
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
