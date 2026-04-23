import 'package:flutter/material.dart';
import 'package:todo_lock_app/app.dart';
import 'package:todo_lock_app/services/hive_service.dart';
import 'package:todo_lock_app/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final hiveService = HiveService();
  await hiveService.init();

  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  // Restore ongoing notification on app start
  final incomplete = hiveService.getIncompleteTodos();
  await notificationService.updateOngoingNotification(incomplete);

  runApp(TodoApp(
    hiveService: hiveService,
    notificationService: notificationService,
  ));
}
