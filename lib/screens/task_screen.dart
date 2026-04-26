import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../widgets/task_card.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/task_header.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key, required this.user});

  final User user;

  void _openTaskForm(BuildContext context, {Task? task}) {
    TaskFormSheet.show(
      context,
      task: task,
      userId: user.id!,
      onSaved: () => context.read<TaskProvider>().loadTasks(),
    );
  }

  Future<void> _deleteTask(BuildContext context, Task task) async {
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
    if (!context.mounted) return;

    await context.read<TaskProvider>().deleteTask(task);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('My Tasks'),
            actions: [
              IconButton(
                onPressed: provider.loadTasks,
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh',
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openTaskForm(context),
            icon: const Icon(Icons.add),
            label: const Text('New Task'),
          ),
          body: RefreshIndicator(
            onRefresh: provider.loadTasks,
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      TaskHeader(
                        userName: user.fullName,
                        pendingCount: provider.pendingCount,
                      ),
                      Expanded(
                        child: provider.tasks.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                itemCount: provider.tasks.length,
                                itemBuilder: (context, index) {
                                  final task = provider.tasks[index];
                                  return TaskCard(
                                    task: task,
                                    onToggle: (v) =>
                                        provider.toggleStatus(task, v == true),
                                    onEdit: () =>
                                        _openTaskForm(context, task: task),
                                    onDelete: () =>
                                        _deleteTask(context, task),
                                    onFavorite: () =>
                                        provider.toggleFavorite(task),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        );
      },
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
