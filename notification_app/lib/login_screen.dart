import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'main.dart';

// LoginController for handling login logic
class LoginController extends GetxController {
  final isLoading = false.obs;
  final obscurePassword = true.obs;
  final storage = const FlutterSecureStorage();

  // Access the global AppController
  final AppController appController = Get.find<AppController>();

  void togglePasswordVisibility() => obscurePassword.toggle();

  Future<void> login(String username, String password) async {
    isLoading.value = true;

    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();

      final response = await http.post(
        Uri.parse('http://192.168.100.83:3000/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'fcm_token': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _handleSuccessfulLogin(data);
      } else {
        final errorData = jsonDecode(response.body);
        Get.snackbar('Error', errorData['error'] ?? 'Login failed');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred during login');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _handleSuccessfulLogin(Map<String, dynamic> data) async {
    final String? token = data['token'];
    final dynamic userId = data['userId'];
    final String? role = data['role'];

    final int? parsedUserId =
        (userId is int) ? userId : int.tryParse(userId.toString());

    if (token != null && parsedUserId != null && role != null) {
      await storage.write(key: 'auth_token', value: token);
      await storage.write(key: 'user_id', value: parsedUserId.toString());
      await storage.write(key: 'role', value: role);

      appController.login(parsedUserId);

      Get.offNamed(role == 'admin' ? '/admin' : '/user/$parsedUserId');
    } else {
      Get.snackbar('Error', 'Invalid response format from server');
    }
  }
}

// LoginScreen Widget
class LoginScreen extends StatelessWidget {
  LoginScreen({Key? key}) : super(key: key);

  final LoginController controller = Get.put(LoginController());
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter your username'
                      : null,
                ),
                const SizedBox(height: 16),
                Obx(() => TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            controller.obscurePassword.value
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: controller.togglePasswordVisibility,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: controller.obscurePassword.value,
                      validator: (value) => value?.isEmpty ?? true
                          ? 'Please enter your password'
                          : null,
                    )),
                const SizedBox(height: 24),
                Obx(() => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            controller.login(
                              _usernameController.text.trim(),
                              _passwordController.text,
                            );
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text('Login', style: TextStyle(fontSize: 18)),
                        ),
                      )),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Get.toNamed('/register'),
                  child: const Text('Don\'t have an account? Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
