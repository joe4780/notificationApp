import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'admin_screen.dart';
import 'user_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegistrationScreen(),
        '/admin': (context) => const AdminScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/user') {
          final args = settings.arguments as Map<String, dynamic>?;
          final userId = args?['userId'] as int?;
          if (userId != null) {
            return MaterialPageRoute(
              builder: (context) => UserScreen(userId: userId),
            );
          }
        }
        // If route is not found, navigate to login screen
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      },
    );
  }
}
