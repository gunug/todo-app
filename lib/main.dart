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

  runApp(TodoApp(
    hiveService: hiveService,
    notificationService: notificationService,
  ));

  // Run after UI is shown — avoids black screen while waiting for dialogs
  await notificationService.requestPermissions();
  final incomplete = hiveService.getIncompleteTodos();
  await notificationService.updateOngoingNotification(incomplete);
}
