import 'package:flutter/material.dart';
import 'package:todo_lock_app/screens/home_screen.dart';
import 'package:todo_lock_app/services/hive_service.dart';
import 'package:todo_lock_app/services/notification_service.dart';

class TodoApp extends StatelessWidget {
  final HiveService hiveService;
  final NotificationService notificationService;

  const TodoApp({
    super.key,
    required this.hiveService,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TodoLift',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(
        hiveService: hiveService,
        notificationService: notificationService,
      ),
    );
  }
}
