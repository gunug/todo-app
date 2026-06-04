import 'package:flutter/material.dart';
import 'package:todo_lock_app/l10n/app_l10n.dart';
import 'package:todo_lock_app/models/todo.dart';
import 'package:todo_lock_app/services/hive_service.dart';
import 'package:uuid/uuid.dart';

class AddEditTodoDialog extends StatefulWidget {
  final HiveService hiveService;
  final Todo? existingTodo;

  const AddEditTodoDialog({
    super.key,
    required this.hiveService,
    this.existingTodo,
  });

  @override
  State<AddEditTodoDialog> createState() => _AddEditTodoDialogState();
}

class _AddEditTodoDialogState extends State<AddEditTodoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool get _isEditing => widget.existingTodo != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingTodo?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingTodo?.description ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isEditing) {
      final todo = widget.existingTodo!;
      todo.title = _titleController.text.trim();
      todo.description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      await widget.hiveService.updateTodo(todo);
    } else {
      final todo = Todo(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );
      await widget.hiveService.addTodo(todo);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AlertDialog(
      title: Text(_isEditing ? l10n.editTodo : l10n.newTodo),
      scrollable: true,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: l10n.titleLabel,
                hintText: l10n.titleHint,
                border: const OutlineInputBorder(),
              ),
              autofocus: !_isEditing,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return l10n.titleRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.descriptionLabel,
                hintText: l10n.descriptionHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: Icon(_isEditing ? Icons.save : Icons.add),
          label: Text(_isEditing ? l10n.save : l10n.add),
        ),
      ],
    );
  }
}
