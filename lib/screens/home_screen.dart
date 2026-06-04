import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:todo_lock_app/l10n/app_l10n.dart';
import 'package:todo_lock_app/models/todo.dart';
import 'package:todo_lock_app/screens/add_edit_todo_screen.dart';
import 'package:todo_lock_app/screens/settings_screen.dart';
import 'package:todo_lock_app/services/hive_service.dart';
import 'package:todo_lock_app/services/settings_service.dart';
import 'package:todo_lock_app/widgets/empty_state_widget.dart';
import 'package:todo_lock_app/widgets/todo_list_tile.dart';

class HomeScreen extends StatefulWidget {
  final HiveService hiveService;
  final SettingsService settingsService;
  final ValueNotifier<Locale> localeNotifier;

  const HomeScreen({
    super.key,
    required this.hiveService,
    required this.settingsService,
    required this.localeNotifier,
  });

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
    final l10n = AppL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(days: 1),
        content: Row(
          children: [
            Expanded(child: Text(l10n.deletedMessage(todo.title))),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () {
                messenger.hideCurrentSnackBar();
                _restoreTodo(todo);
              },
              child: Text(l10n.undo),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: () => messenger.hideCurrentSnackBar(),
              child: Text(l10n.confirm),
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

  Future<void> _openSettings() async {
    await showDialog(
      context: context,
      builder: (_) => SettingsDialog(
        settingsService: widget.settingsService,
        localeNotifier: widget.localeNotifier,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
            tooltip: l10n.settings,
          ),
        ],
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
