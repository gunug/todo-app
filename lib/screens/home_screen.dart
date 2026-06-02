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

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        // Stays until user taps 확인 or 되돌리기 — no auto-dismiss
        duration: const Duration(days: 1),
        content: Row(
          children: [
            Expanded(child: Text("'${todo.title}' 삭제됨 / Deleted")),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () {
                messenger.hideCurrentSnackBar();
                _restoreTodo(todo);
              },
              child: const Text('되돌리기 / Undo'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => messenger.hideCurrentSnackBar(),
              child: const Text('확인 / Confirm'),
            ),
          ],
        ),
      ),
    );
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
    await showDialog(
      context: context,
      builder: (_) => AddEditTodoDialog(
        hiveService: widget.hiveService,
        existingTodo: todo,
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
