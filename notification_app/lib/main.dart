import 'package:flutter/material.dart';
import 'post.dart'; // Import the ApiService class

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
  final ApiService apiService =
      ApiService('http://localhost:3000'); // Initialize ApiService

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchNotifications();
  }

  Future<void> _fetchUsers() async {
    try {
      final usersData = await apiService.fetchUsers();
      setState(() {
        _users = List<String>.from(usersData.map((user) => user['name']));
      });
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> _fetchNotifications() async {
    try {
      final notificationsData = await apiService.fetchNotifications();
      setState(() {
        _notifications = notificationsData;
      });
    } catch (e) {
      print('Error fetching notifications: $e');
    }
  }

  Future<void> _sendNotification() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final usersData = await apiService.fetchUsers();
        final userIdsMap = {
          for (var user in usersData) user['name']: user['id']
        };
        final selectedUserIds =
            _selectedUsers.map((name) => userIdsMap[name]).toList();

        final response = await apiService.sendNotification(
          _message,
          selectedUserIds.cast<int>(),
          _expiryDate,
        );

        if (response['error'] == null) {
          _fetchNotifications();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Notification sent!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['error'])),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending notification: $e')),
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
              Text(
                'Selected Users: ${_selectedUsers.length}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 20),
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
              Text('Notifications',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 10),
              _notifications.isNotEmpty
                  ? ListView.builder(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        final isRead =
                            notification['is_read'] == 1; // Convert to boolean
                        return ListTile(
                          title: Text(notification['message']),
                          subtitle: Text(
                              'Sent to: ${notification['user_id']} - Read: $isRead'),
                          trailing: isRead
                              ? const Icon(Icons.check, color: Colors.green)
                              : const Icon(Icons.clear, color: Colors.red),
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
