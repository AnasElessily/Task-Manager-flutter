import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/db_helper.dart';
import '../models/task.dart';
import '../utils/api_service.dart';

class TaskProvider extends ChangeNotifier {
  final int userId;

  TaskProvider({required this.userId});

  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => List.unmodifiable(_tasks);

  List<Task> get favoriteTasks =>
      _tasks.where((t) => t.isFavorite == 1).toList();

  int get pendingCount => _tasks.where((t) => t.isCompleted == 0).length;

  bool get isLoading => _isLoading;

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadTasks() async {
    _isLoading = true;
    notifyListeners();

    final tasks = await DBHelper.getTasks(userId);
    _sortTasks(tasks);
    _tasks = tasks;

    _isLoading = false;
    notifyListeners();

    _syncInBackground();
  }

  void _sortTasks(List<Task> tasks) {
    tasks.sort((a, b) {
      final completedComparison = a.isCompleted.compareTo(b.isCompleted);
      if (completedComparison != 0) return completedComparison;
      return a.dueDate.compareTo(b.dueDate);
    });
  }

  Future<void> _syncInBackground() async {
    try {
      await ApiService.syncTasks(userId, _tasks);
      final remoteTasks = await ApiService.fetchTasks(userId);
      for (final remoteTask in remoteTasks) {
        await DBHelper.insertTask(remoteTask);
      }
      final updated = await DBHelper.getTasks(userId);
      _sortTasks(updated);
      _tasks = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('Sync failed: $e');
    }
  }

  // ── Add ───────────────────────────────────────────────────────────────────

  Future<void> addTask(Task task) async {
    final newTask = task.copyWith(id: task.id ?? const Uuid().v4());
    await DBHelper.insertTask(newTask);
    try {
      await ApiService.syncTasks(userId, [newTask]);
    } catch (_) {}
    await loadTasks();
  }

  // ── Update ────────────────────────────────────────────────────────────────

  Future<void> updateTask(Task task) async {
    await DBHelper.updateTask(task);
    try {
      await ApiService.syncTasks(userId, [task]);
    } catch (_) {}
    await loadTasks();
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteTask(Task task) async {
    try {
      await ApiService.deleteTask(task.id!);
    } catch (_) {}
    await DBHelper.deleteTask(task.id!);
    await loadTasks();
  }

  // ── Toggle Status ─────────────────────────────────────────────────────────

  Future<void> toggleStatus(Task task, bool completed) async {
    final value = completed ? 1 : 0;
    await DBHelper.toggleTask(task.id!, value);

    final updatedTask = task.copyWith(isCompleted: value);
    try {
      await ApiService.syncTasks(userId, [updatedTask]);
    } catch (_) {}

    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      _tasks[idx] = updatedTask;
      _sortTasks(_tasks);
      notifyListeners();
    }
  }

  // ── Toggle Favorite ───────────────────────────────────────────────────────

  Future<void> toggleFavorite(Task task) async {
    final newValue = task.isFavorite == 1 ? 0 : 1;
    await DBHelper.toggleFavorite(task.id!, newValue);

    try {
      await ApiService.toggleFavorite(task.id!, newValue == 1);
    } catch (_) {}

    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(isFavorite: newValue);
      notifyListeners();
    }
  }
}
