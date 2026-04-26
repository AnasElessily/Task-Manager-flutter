import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../models/task.dart';

class DeadlineScreen extends StatefulWidget {
  const DeadlineScreen({super.key});

  @override
  State<DeadlineScreen> createState() => _DeadlineScreenState();
}

class _DeadlineScreenState extends State<DeadlineScreen> {
  Task? _selectedTask;

  DateTime? _parseDate(String dateStr) {
    try {
      // Support yyyy-MM-dd format
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  _DeadlineInfo? _getDeadlineInfo(Task task) {
    final due = _parseDate(task.dueDate);
    if (due == null) return null;
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(due.year, due.month, due.day);
    final diff = dueOnly.difference(todayOnly);
    return _DeadlineInfo(dueDate: dueOnly, today: todayOnly, diff: diff);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final tasks = provider.tasks;
        final currentTask = tasks.isEmpty ? null : tasks.where((t) => t.id == _selectedTask?.id).firstOrNull;

        return Scaffold(
          appBar: AppBar(title: const Text('Deadline Reminder')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Task Selector ─────────────────────────────────────────
                Text(
                  'Select a Task',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButton<Task>(
                    isExpanded: true,
                    underline: const SizedBox(),
                    hint: const Text('Choose a task…'),
                    value: tasks.contains(_selectedTask) ? _selectedTask : null,
                    items: tasks.map((task) {
                      return DropdownMenuItem<Task>(
                        value: task,
                        child: Text(
                          task.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (task) => setState(() => _selectedTask = task),
                  ),
                ),


                const SizedBox(height: 32),

                // ── Deadline Info Card ─────────────────────────────────────
                if (currentTask != null) _buildDeadlineCard(currentTask),

                if (tasks.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 80,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tasks available',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeadlineCard(Task task) {
    final info = _getDeadlineInfo(task);

    if (info == null) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Padding(
          padding: EdgeInsets.all(20),
          child: Text('Could not parse due date format.'),
        ),
      );
    }

    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (info.diff.isNegative) {
      statusColor = Colors.red.shade600;
      statusText = 'Overdue by ${info.diff.inDays.abs()} day(s)!';
      statusIcon = Icons.warning_amber_rounded;
    } else if (info.diff.inDays == 0) {
      statusColor = Colors.orange.shade700;
      statusText = 'Due today!';
      statusIcon = Icons.alarm;
    } else if (info.diff.inDays <= 3) {
      statusColor = Colors.orange.shade600;
      statusText = '${info.diff.inDays} day(s) remaining';
      statusIcon = Icons.hourglass_bottom;
    } else {
      statusColor = Colors.green.shade600;
      statusText = '${info.diff.inDays} day(s) remaining';
      statusIcon = Icons.check_circle_outline;
    }

    String dateFormat(DateTime d) =>
        '${d.day} ${_monthName(d.month)} ${d.year}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Task name banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                task.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Date rows
            _dateRow(
              icon: Icons.event,
              label: 'Task Deadline',
              value: dateFormat(info.dueDate),
              color: Colors.indigo,
            ),
            const Divider(height: 24),
            _dateRow(
              icon: Icons.today,
              label: 'Today',
              value: dateFormat(info.today),
              color: Colors.grey.shade700,
            ),
            const Divider(height: 24),

            // Status badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: statusColor, width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(statusIcon, color: statusColor, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),

            // Priority & status chips
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _chip(
                  label: 'Priority: ${task.priority}',
                  color: _priorityColor(task.priority),
                ),
                const SizedBox(width: 10),
                _chip(
                  label: task.isCompleted == 1
                      ? 'Completed'
                      : 'Pending',
                  color: task.isCompleted == 1
                      ? Colors.green
                      : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 10),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _chip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red.shade600;
      case 'Medium':
        return Colors.orange.shade600;
      default:
        return Colors.green.shade600;
    }
  }

  String _monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }
}

class _DeadlineInfo {
  final DateTime dueDate;
  final DateTime today;
  final Duration diff;

  _DeadlineInfo({
    required this.dueDate,
    required this.today,
    required this.diff,
  });
}
