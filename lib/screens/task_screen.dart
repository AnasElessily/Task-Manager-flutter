import 'package:flutter/material.dart';

import '../database/db_helper.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../utils/api_service.dart';

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

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    final tasks = await DBHelper.getTasks(_currentUser.id!);
    tasks.sort((a, b) {
      final completedComparison = a.isCompleted.compareTo(b.isCompleted);
      if (completedComparison != 0) return completedComparison;
      return a.dueDate.compareTo(b.dueDate);
    });

    if (!mounted) return;

    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });

    // Optional: Auto-sync local changes to remote
    _syncTasks();
  }

  Future<void> _syncTasks() async {
    try {
      // 1. Fetch remote tasks and update local
      final remoteTasks = await ApiService.fetchTasks(_currentUser.id!);
      for (final task in remoteTasks) {
        await DBHelper.insertTask(task);
      }

      // 2. Fetch local tasks and update remote
      final localTasks = await DBHelper.getTasks(_currentUser.id!);
      await ApiService.syncTasks(_currentUser.id!, localTasks);
      
      // Reload UI with synced data
      final updatedTasks = await DBHelper.getTasks(_currentUser.id!);
      updatedTasks.sort((a, b) {
        final completedComparison = a.isCompleted.compareTo(b.isCompleted);
        if (completedComparison != 0) return completedComparison;
        return a.dueDate.compareTo(b.dueDate);
      });
      
      if (!mounted) return;
      setState(() {
        _tasks = updatedTasks;
      });
    } catch (e) {
      debugPrint("Sync failed: $e");
    }
  }

  Future<void> _showTaskForm({Task? task}) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: task?.title ?? '');
    final descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    DateTime? selectedDate = task != null
        ? DateTime.tryParse(task.dueDate)
        : null;
    String selectedPriority = task?.priority ?? 'Medium';

    Future<void> pickDate(StateSetter setModalState) async {
      final now = DateTime.now();
      final initialDate = selectedDate ?? now;
      final pickedDate = await showDatePicker(
        context: context,
        initialDate: initialDate.isBefore(now) ? now : initialDate,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 10),
      );

      if (pickedDate != null) {
        setModalState(() {
          selectedDate = pickedDate;
        });
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task == null ? 'Add New Task' : 'Edit Task',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: titleController,
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
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Task Description',
                          prefixIcon: Icon(Icons.description_outlined),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => pickDate(setModalState),
                        borderRadius: BorderRadius.circular(16),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Due Date',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                          child: Text(
                            selectedDate == null
                                ? 'Select due date'
                                : _formatDate(selectedDate!),
                            style: TextStyle(
                              color: selectedDate == null
                                  ? Theme.of(context).hintColor
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      if (selectedDate == null)
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
                        initialValue: selectedPriority,
                        decoration: const InputDecoration(
                          labelText: 'Priority Level',
                          prefixIcon: Icon(Icons.flag_outlined),
                        ),
                        items: const ['Low', 'Medium', 'High']
                            .map(
                              (priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setModalState(() {
                              selectedPriority = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            if (selectedDate == null) {
                              setModalState(() {});
                              return;
                            }

                            final newTask = Task(
                              id: task?.id,
                              userId: _currentUser.id!,
                              title: titleController.text.trim(),
                              description: descriptionController.text.trim().isEmpty
                                  ? null
                                  : descriptionController.text.trim(),
                              dueDate: _formatDate(selectedDate!),
                              priority: selectedPriority,
                              isCompleted: task?.isCompleted ?? 0,
                            );

                            if (task == null) {
                              await DBHelper.insertTask(newTask);
                            } else {
                              await DBHelper.updateTask(newTask);
                            }

                            if (!mounted) return;
                            Navigator.pop(context);
                            await _loadTasks();

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  task == null
                                      ? 'Task added successfully'
                                      : 'Task updated successfully',
                                ),
                              ),
                            );
                          },
                          child: Text(
                            task == null ? 'Add Task' : 'Save Changes',
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _deleteTask(Task task) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
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
        );
      },
    );

    if (shouldDelete != true) return;

    await DBHelper.deleteTask(task.id!);
    await _loadTasks();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Task deleted')));
  }

  Future<void> _toggleTaskStatus(Task task, bool? value) async {
    await DBHelper.toggleTask(task.id!, value == true ? 1 : 0);
    await _loadTasks();
  }

  Color _priorityColor(String priority, BuildContext context) {
    switch (priority) {
      case 'High':
        return Colors.red.shade400;
      case 'Medium':
        return Colors.orange.shade400;
      case 'Low':
        return Colors.green.shade400;
      default:
        return Theme.of(context).colorScheme.primary;
    }
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
        onPressed: () => _showTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text("New Task"),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello, ${_currentUser.fullName.split(' ').first}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You have ${_tasks.where((task) => task.isCompleted == 0).length} pending tasks',
                          style: TextStyle(
                            color: Colors.white.withAlpha(200),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _tasks.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              const SizedBox(height: 100),
                              Icon(Icons.assignment_turned_in_outlined, size: 100, color: Colors.grey.shade400),
                              const SizedBox(height: 24),
                              Text(
                                'No tasks yet',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add your first task.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _tasks.length,
                            itemBuilder: (context, index) {
                              final task = _tasks[index];
                              final isCompleted = task.isCompleted == 1;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: isCompleted ? 0 : 2,
                                color: isCompleted ? Colors.grey.shade100 : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: isCompleted ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    leading: Transform.scale(
                                      scale: 1.2,
                                      child: Checkbox(
                                        value: isCompleted,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                        onChanged: (value) => _toggleTaskStatus(task, value),
                                      ),
                                    ),
                                    title: Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: isCompleted ? Colors.grey : Colors.black87,
                                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 8),
                                        if (task.description != null && task.description!.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8),
                                            child: Text(
                                              task.description!,
                                              style: TextStyle(color: Colors.grey.shade600),
                                            ),
                                          ),
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                                            const SizedBox(width: 4),
                                            Text(
                                              task.dueDate,
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _priorityColor(task.priority, context).withAlpha(46),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(color: _priorityColor(task.priority, context)),
                                              ),
                                              child: Text(
                                                task.priority,
                                                style: TextStyle(
                                                  color: _priorityColor(task.priority, context),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showTaskForm(task: task);
                                        } else if (value == 'delete') {
                                          _deleteTask(task);
                                        }
                                      },
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      itemBuilder: (context) => const [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 20),
                                              SizedBox(width: 8),
                                              Text('Edit'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                              SizedBox(width: 8),
                                              Text('Delete', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
