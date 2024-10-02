# notification_app

An in-app notification system where an admin, using the web app
backend, can send notifications to specific users in the Flutter app and see if the users have read or not as shown here ![alt text](adminpanel.jpg). These notifications will be
stored and retrieved from a MySQL database, and delivered through an API.T he users can receive the notification in their mobile phones as a pop up on top of the screen as shown here ![alt text](notification.jpg)
.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## running devices on an ip address using an ip address:
1. adb tcpip 5555
2. device one, adb connect <device-ip>:5555
   device two, adb connect <device-ip>:5555
3. verify connected devices: adb devices