import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../utils/api_service.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/task_header.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key, required this.user});

  final User user;

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  bool _isLoading = true;
  List<Task> _tasks = [];

  User get _currentUser => widget.user;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);

    final tasks = await DBHelper.getTasks(_currentUser.id!);
    _sortTasks(tasks);

    if (!mounted) return;
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });

    _syncTasks();
  }

  void _sortTasks(List<Task> tasks) {
    tasks.sort((a, b) {
      final completedComparison = a.isCompleted.compareTo(b.isCompleted);
      if (completedComparison != 0) return completedComparison;
      return a.dueDate.compareTo(b.dueDate);
    });
  }

  Future<void> _syncTasks() async {
    try {
      final localTasks = await DBHelper.getTasks(_currentUser.id!);
      await ApiService.syncTasks(_currentUser.id!, localTasks);

      final remoteTasks = await ApiService.fetchTasks(_currentUser.id!);
      for (final remoteTask in remoteTasks) {
        await DBHelper.insertTask(remoteTask);
      }

      final updatedTasks = await DBHelper.getTasks(_currentUser.id!);
      _sortTasks(updatedTasks);

      if (!mounted) return;
      setState(() => _tasks = updatedTasks);
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  Future<void> _deleteTask(Task task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    try {
      await ApiService.deleteTask(task.id!);
    } catch (e) {
      debugPrint('Remote delete failed: $e');
    }

    await DBHelper.deleteTask(task.id!);
    await _loadTasks();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task deleted')),
    );
  }

  Future<void> _toggleTaskStatus(Task task, bool? value) async {
    await DBHelper.toggleTask(task.id!, value == true ? 1 : 0);
    await _loadTasks();
  }

  void _openTaskForm({Task? task}) {
    TaskFormSheet.show(
      context,
      task: task,
      userId: _currentUser.id!,
      onSaved: _loadTasks,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            onPressed: _loadTasks,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openTaskForm,
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  TaskHeader(
                    userName: _currentUser.fullName,
                    pendingCount:
                        _tasks.where((t) => t.isCompleted == 0).length,
                  ),
                  Expanded(
                    child: _tasks.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            itemCount: _tasks.length,
                            itemBuilder: (context, index) {
                              final task = _tasks[index];
                              return TaskCard(
                                task: task,
                                onToggle: (v) => _toggleTaskStatus(task, v),
                                onEdit: () => _openTaskForm(task: task),
                                onDelete: () => _deleteTask(task),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 100),
        Icon(
          Icons.assignment_turned_in_outlined,
          size: 100,
          color: Colors.grey.shade400,
        ),
        const SizedBox(height: 24),
        Text(
          'No tasks yet',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the + button to add your first task.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
