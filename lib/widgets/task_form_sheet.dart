import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/db_helper.dart';
import '../models/task.dart';

class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({
    super.key,
    this.task,
    required this.userId,
    required this.onSaved,
  });

  final Task? task;
  final int userId;
  final VoidCallback onSaved;

  static Future<void> show(
    BuildContext context, {
    Task? task,
    required int userId,
    required VoidCallback onSaved,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => TaskFormSheet(
        task: task,
        userId: userId,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _selectedPriority;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(
      text: widget.task?.description ?? '',
    );
    _selectedPriority = widget.task?.priority ?? 'Medium';
    _selectedDate =
        widget.task != null ? DateTime.tryParse(widget.task!.dueDate) : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      setState(() {});
      return;
    }

    final newTask = Task(
      id: widget.task?.id ?? const Uuid().v4(),
      userId: widget.userId,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dueDate: _formatDate(_selectedDate!),
      priority: _selectedPriority,
      isCompleted: widget.task?.isCompleted ?? 0,
    );

    if (widget.task == null) {
      await DBHelper.insertTask(newTask);
    } else {
      await DBHelper.updateTask(newTask);
    }

    if (!mounted) return;

    // Capture everything before the pop so we don't use a stale context.
    final messenger = ScaffoldMessenger.of(context);
    final message = widget.task == null
        ? 'Task added successfully'
        : 'Task updated successfully';

    Navigator.pop(context);
    widget.onSaved();

    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.task == null ? 'Add New Task' : 'Edit Task',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Task title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Task Description',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select due date'
                        : _formatDate(_selectedDate!),
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Theme.of(context).hintColor
                          : null,
                    ),
                  ),
                ),
              ),
              if (_selectedDate == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: Text(
                    'Due date is required',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedPriority,
                decoration: const InputDecoration(
                  labelText: 'Priority Level',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                items: const ['Low', 'Medium', 'High']
                    .map(
                      (p) => DropdownMenuItem(value: p, child: Text(p)),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedPriority = value);
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  child: Text(
                    widget.task == null ? 'Add Task' : 'Save Changes',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
