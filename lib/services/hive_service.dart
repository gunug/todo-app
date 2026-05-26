import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:todo_lock_app/hive_registrar.g.dart';
import 'package:todo_lock_app/models/todo.dart';

class HiveService {
  static const String _boxName = 'todos';
  late Box<Todo> _box;

  Box<Todo> get box => _box;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapters();
    _box = await Hive.openBox<Todo>(_boxName);
  }

  List<Todo> getAllTodos() {
    return _box.values.toList()
      ..sort((a, b) {
        // 핀 고정 우선
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        // 미완료 우선 (완료 항목은 맨 아래)
        if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
        // sortOrder 오름차순
        if (a.sortOrder != b.sortOrder) return a.sortOrder.compareTo(b.sortOrder);
        // 최신순
        return b.createdAt.compareTo(a.createdAt);
      });
  }

  Future<void> reorderTodos(List<Todo> todos) async {
    for (var i = 0; i < todos.length; i++) {
      todos[i].sortOrder = i;
      await _box.put(todos[i].id, todos[i]);
    }
  }

  List<Todo> getIncompleteTodos() {
    return getAllTodos().where((t) => !t.isCompleted).toList();
  }

  Future<void> addTodo(Todo todo) async {
    await _box.put(todo.id, todo);
  }

  Future<void> updateTodo(Todo todo) async {
    await _box.put(todo.id, todo);
  }

  Future<void> deleteTodo(String id) async {
    await _box.delete(id);
  }

  Todo? getTodo(String id) {
    return _box.get(id);
  }
}
