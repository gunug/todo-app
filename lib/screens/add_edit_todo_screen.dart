import 'package:flutter/material.dart';
import 'package:todo_lock_app/models/todo.dart';
import 'package:todo_lock_app/services/hive_service.dart';
import 'package:uuid/uuid.dart';

class AddEditTodoScreen extends StatefulWidget {
  final HiveService hiveService;
  final Todo? existingTodo;

  const AddEditTodoScreen({
    super.key,
    required this.hiveService,
    this.existingTodo,
  });

  @override
  State<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends State<AddEditTodoScreen> {
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

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '할일 수정 / Edit Todo' : '새 할일 / New Todo'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '제목 / Title',
                hintText: '할일을 입력하세요 / Enter a todo',
                border: OutlineInputBorder(),
              ),
              autofocus: !_isEditing,
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '제목을 입력해주세요 / Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '설명 / Description (선택 / optional)',
                hintText: '상세 설명을 입력하세요 / Enter a description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(_isEditing ? '저장 / Save' : '추가 / Add'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
