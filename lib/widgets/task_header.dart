import 'package:flutter/material.dart';

class TaskHeader extends StatelessWidget {
  const TaskHeader({
    super.key,
    required this.userName,
    required this.pendingCount,
  });

  final String userName;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            'Hello, ${userName.split(' ').first}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You have $pendingCount pending tasks',
            style: TextStyle(
              color: Colors.white.withAlpha(200),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
