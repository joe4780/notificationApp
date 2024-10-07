import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// RegistrationController using GetX
class RegistrationController extends GetxController {
  final isLoading = false.obs;
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController roleController = TextEditingController();
  final storage = const FlutterSecureStorage();

  // Function to handle user registration
  Future<void> register() async {
    if (usernameController.text.isEmpty ||
        passwordController.text.isEmpty ||
        roleController.text.isEmpty) {
      Get.snackbar('Error', 'Please fill in all fields');
      return;
    }

    isLoading.value = true;

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.83:3000/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': usernameController.text.trim(),
          'password': passwordController.text.trim(),
          'role': roleController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        Get.snackbar('Success', data['message']);
        Get.offNamed('/login');
      } else {
        final data = jsonDecode(response.body);
        Get.snackbar('Error', data['error'] ?? 'Registration failed');
      }
    } catch (e) {
      Get.snackbar('Error', 'An error occurred during registration');
    } finally {
      isLoading.value = false;
    }
  }
}

// RegistrationScreen Widget using GetX
class RegistrationScreen extends StatelessWidget {
  RegistrationScreen({Key? key}) : super(key: key);

  final RegistrationController controller = Get.put(RegistrationController());
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
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
                  controller: controller.usernameController,
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
                TextFormField(
                  controller: controller.passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter your password'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller.roleController,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.group),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter your role' : null,
                ),
                const SizedBox(height: 24),
                Obx(() => controller.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            controller.register();
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child:
                              Text('Register', style: TextStyle(fontSize: 18)),
                        ),
                      )),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Get.toNamed('/login'),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
