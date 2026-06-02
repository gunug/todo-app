import 'package:flutter/material.dart';
import 'package:todo_lock_app/models/todo.dart';
import 'package:todo_lock_app/services/hive_service.dart';
import 'package:todo_lock_app/services/notification_service.dart';
import 'package:uuid/uuid.dart';

class AddEditTodoScreen extends StatefulWidget {
  final HiveService hiveService;
  final NotificationService notificationService;
  final Todo? existingTodo;

  const AddEditTodoScreen({
    super.key,
    required this.hiveService,
    required this.notificationService,
    this.existingTodo,
  });

  @override
  State<AddEditTodoScreen> createState() => _AddEditTodoScreenState();
}

class _AddEditTodoScreenState extends State<AddEditTodoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  DateTime? _reminderTime;
  bool get _isEditing => widget.existingTodo != null;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingTodo?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingTodo?.description ?? '');
    _reminderTime = widget.existingTodo?.reminderTime;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderTime ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime:
          _reminderTime != null
              ? TimeOfDay.fromDateTime(_reminderTime!)
              : TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    setState(() {
      _reminderTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final ns = widget.notificationService;

    if (_isEditing) {
      final todo = widget.existingTodo!;

      // Cancel old reminder if it existed
      if (todo.notificationId != null) {
        await ns.cancelReminder(todo.notificationId!);
      }

      todo.title = _titleController.text.trim();
      todo.description = _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim();
      todo.reminderTime = _reminderTime;

      // Schedule new reminder if set
      if (_reminderTime != null && !todo.isCompleted) {
        final nid = ns.generateNotificationId();
        todo.notificationId = nid;
        await ns.scheduleReminder(
          notificationId: nid,
          title: todo.title,
          description: todo.description,
          scheduledTime: _reminderTime!,
        );
      } else {
        todo.notificationId = null;
      }

      await widget.hiveService.updateTodo(todo);
    } else {
      int? notificationId;
      if (_reminderTime != null) {
        notificationId = ns.generateNotificationId();
        await ns.scheduleReminder(
          notificationId: notificationId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          scheduledTime: _reminderTime!,
        );
      }

      final todo = Todo(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: DateTime.now(),
        reminderTime: _reminderTime,
        notificationId: notificationId,
      );

      await widget.hiveService.addTodo(todo);
    }

    // Update ongoing notification
    final incomplete = widget.hiveService.getIncompleteTodos();
    await ns.updateOngoingNotification(incomplete);

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
            const SizedBox(height: 24),
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.notifications_outlined,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('알림 예약 / Set Reminder'),
                subtitle: _reminderTime != null
                    ? Text(
                        '${_reminderTime!.year}/${_reminderTime!.month}/${_reminderTime!.day} '
                        '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}',
                      )
                    : const Text('탭하여 알림 시간을 설정하세요 / Tap to set reminder time'),
                trailing: _reminderTime != null
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _reminderTime = null),
                      )
                    : null,
                onTap: _pickReminderTime,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: Icon(_isEditing ? Icons.save : Icons.add),
              label: Text(_isEditing ? '수정 / Edit' : '추가 / Add'),
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
