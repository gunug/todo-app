import 'package:flutter/material.dart';
import 'package:todo_lock_app/models/todo.dart';

class TodoListTile extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onTogglePin;

  const TodoListTile({
    super.key,
    required this.todo,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
    required this.onTogglePin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        if (!todo.isCompleted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('완료된 할일만 삭제 가능합니다 / Only completed todos can be deleted'),
                duration: Duration(seconds: 2),
              ),
            );
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: todo.isCompleted
            ? theme.colorScheme.error
            : theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.delete,
          color: todo.isCompleted
              ? theme.colorScheme.onError
              : theme.colorScheme.outline,
        ),
      ),
      child: ListTile(
        leading: Checkbox(
          value: todo.isCompleted,
          onChanged: (_) => onToggle(),
          shape: const CircleBorder(),
        ),
        title: Text(
          todo.title,
          style: TextStyle(
            decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
            color: todo.isCompleted
                ? theme.colorScheme.outline
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: todo.description != null && todo.description!.isNotEmpty
            ? Text(
                todo.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        onTap: onTap,
        trailing: IconButton(
          icon: Icon(
            todo.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
            size: 20,
            color: todo.isPinned
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
          onPressed: onTogglePin,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }
}
