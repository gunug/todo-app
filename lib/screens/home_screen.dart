import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:todo_lock_app/models/todo.dart';
import 'package:todo_lock_app/screens/add_edit_todo_screen.dart';
import 'package:todo_lock_app/services/hive_service.dart';
import 'package:todo_lock_app/widgets/empty_state_widget.dart';
import 'package:todo_lock_app/widgets/todo_list_tile.dart';

class HomeScreen extends StatefulWidget {
  final HiveService hiveService;

  const HomeScreen({super.key, required this.hiveService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _toggleTodo(Todo todo) async {
    todo.isCompleted = !todo.isCompleted;
    await widget.hiveService.updateTodo(todo);
  }

  Future<void> _deleteTodo(Todo todo) async {
    await widget.hiveService.deleteTodo(todo.id);

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text("'${todo.title}' 삭제됨 / Deleted"),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '되돌리기 / Undo',
              onPressed: () => _restoreTodo(todo),
            ),
          ),
        );
    }
  }

  Future<void> _restoreTodo(Todo todo) async {
    await widget.hiveService.addTodo(todo);
  }

  Future<void> _togglePin(Todo todo) async {
    todo.isPinned = !todo.isPinned;
    await widget.hiveService.updateTodo(todo);
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final todos = widget.hiveService.getAllTodos();
    if (oldIndex < newIndex) newIndex--;
    final item = todos.removeAt(oldIndex);
    todos.insert(newIndex, item);
    await widget.hiveService.reorderTodos(todos);
  }

  Future<void> _openAddEdit({Todo? todo}) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTodoScreen(
          hiveService: widget.hiveService,
          existingTodo: todo,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('할일 목록 / Todo List'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder(
        valueListenable: widget.hiveService.box.listenable(),
        builder: (context, Box<Todo> box, _) {
          final todos = widget.hiveService.getAllTodos();

          if (todos.isEmpty) {
            return const EmptyStateWidget();
          }

          return ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: todos.length,
            onReorder: _onReorder,
            proxyDecorator: (child, index, animation) {
              return Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final todo = todos[index];
              return TodoListTile(
                key: ValueKey(todo.id),
                todo: todo,
                onToggle: () => _toggleTodo(todo),
                onTap: () => _openAddEdit(todo: todo),
                onDelete: () => _deleteTodo(todo),
                onTogglePin: () => _togglePin(todo),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
