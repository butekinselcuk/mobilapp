// notification_permission_web.dart
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
String getWebNotificationPermission() => html.Notification.permission ?? ''; 