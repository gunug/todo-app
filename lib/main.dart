import 'package:flutter/material.dart';
import 'package:todo_lock_app/app.dart';
import 'package:todo_lock_app/services/hive_service.dart';
import 'package:todo_lock_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveService = HiveService();
  await hiveService.init();

  final notificationService = NotificationService();

  runApp(TodoApp(
    hiveService: hiveService,
    notificationService: notificationService,
  ));

  // Notification init runs after UI is shown — never blocks runApp
  notificationService.initInBackground(hiveService);
}
