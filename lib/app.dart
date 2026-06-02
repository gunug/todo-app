import 'package:flutter/material.dart';
import 'package:todo_lock_app/screens/home_screen.dart';
import 'package:todo_lock_app/services/hive_service.dart';

class TodoApp extends StatelessWidget {
  final HiveService hiveService;

  const TodoApp({super.key, required this.hiveService});

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
      home: HomeScreen(hiveService: hiveService),
    );
  }
}
