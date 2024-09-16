import 'package:firebase_messaging/firebase_messaging.dart';

class FirebaseApi {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    await firebaseMessaging.requestPermission();

    final String? fcmToken = await firebaseMessaging.getToken();
    print('Token: $fcmToken');
  }
}
