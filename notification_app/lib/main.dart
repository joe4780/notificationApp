import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'admin_screen.dart';
import 'user_screen.dart';

// Background message handler for Firebase Messaging
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling a background message: ${message.messageId}');
}

// Define the AppController directly
class AppController extends GetxController {
  var isLoggedIn = false.obs;
  var currentUserId = 0.obs;

  void login(int userId) {
    isLoggedIn.value = true;
    currentUserId.value = userId;
  }

  void logout() {
    isLoggedIn.value = false;
    currentUserId.value = 0;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase based on platform
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCtDOKuN4d1gprPXytHY5yMnaRmJy7mhiE",
        authDomain: "notificationsapp-a3306.firebaseapp.com",
        projectId: "notificationsapp-a3306",
        storageBucket: "notificationsapp-a3306.appspot.com",
        messagingSenderId: "731488632895",
        appId: "1:731488632895:web:6c7274bc43b10e2aeeb88a",
        measurementId: "G-KCEV8X8MRV",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

  // Set up background message handler for Firebase
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize Firebase Messaging and request permissions
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else {
    print('User declined or has not accepted permission');
  }

  // Get and print the FCM token
  String? token = await messaging.getToken();
  print('FCM Token: $token');

  // Initialize AppController using Get
  Get.put(AppController()); // Register the global AppController here

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Notification App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => LoginScreen()),
        GetPage(name: '/register', page: () => RegistrationScreen()),
        GetPage(name: '/admin', page: () => AdminScreen()),
        GetPage(
          name: '/user/:userId',
          page: () =>
              UserScreen(userId: int.parse(Get.parameters['userId'] ?? '0')),
        ),
      ],
      unknownRoute: GetPage(name: '/notfound', page: () => LoginScreen()),
    );
  }
}
