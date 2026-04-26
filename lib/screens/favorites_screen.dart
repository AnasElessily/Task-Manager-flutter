import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../models/task.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red.shade400;
      case 'Medium':
        return Colors.orange.shade400;
      case 'Low':
        return Colors.green.shade400;
      default:
        return Colors.indigo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        final favorites = provider.favoriteTasks;

        return Scaffold(
          appBar: AppBar(title: const Text('Favorite Tasks')),
          body: favorites.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final task = favorites[index];
                    return _FavoriteCard(
                      task: task,
                      priorityColor: _priorityColor(task.priority),
                      onRemove: () => provider.toggleFavorite(task),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_border, size: 100, color: Colors.grey.shade300),
          const SizedBox(height: 24),
          Text(
            'No favorite tasks yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the ★ on any task to mark it as favorite.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({
    required this.task,
    required this.priorityColor,
    required this.onRemove,
  });

  final Task task;
  final Color priorityColor;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.isCompleted == 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Star icon
            const Padding(
              padding: EdgeInsets.only(top: 2, right: 12),
              child: Icon(Icons.star, color: Colors.amber, size: 24),
            ),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        task.dueDate,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withAlpha(40),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: priorityColor),
                        ),
                        child: Text(
                          task.priority,
                          style: TextStyle(
                            fontSize: 12,
                            color: priorityColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? Colors.green.shade50
                              : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isCompleted
                                ? Colors.green.shade400
                                : Colors.orange.shade400,
                          ),
                        ),
                        child: Text(
                          isCompleted ? 'Completed' : 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: isCompleted
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Remove button
            IconButton(
              icon: const Icon(Icons.star, color: Colors.amber),
              tooltip: 'Remove from favorites',
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
