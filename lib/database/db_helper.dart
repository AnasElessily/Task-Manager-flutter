import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/user.dart';
import '../models/task.dart';
import '../utils/password_helper.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'app.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        // USERS TABLE
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            fullName TEXT,
            email TEXT UNIQUE,
            studentId TEXT,
            gender TEXT,
            level INTEGER,
            password TEXT,
            profileImage TEXT
          )
        ''');

        // TASKS TABLE
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER,
            title TEXT,
            description TEXT,
            dueDate TEXT,
            priority TEXT,
            isCompleted INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          final users = await db.query('users', columns: ['id', 'password']);

          for (final user in users) {
            final id = user['id'] as int?;
            final password = user['password'] as String?;

            if (id == null || password == null || PasswordHelper.isHashed(password)) {
              continue;
            }

            await db.update(
              'users',
              {'password': PasswordHelper.hashPassword(password)},
              where: 'id = ?',
              whereArgs: [id],
            );
          }
        }
      },
    );
  }

  // USERS

  static Future<int> insertUser(User user) async {
    final db = await database;
    final userMap = user.toMap();
    userMap['password'] = PasswordHelper.normalizeForStorage(user.password);
    return await db.insert('users', userMap);
  }

  static Future<User?> getUser(String email, String password) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    // 1. Email doesn't exist
    if (result.isEmpty) {
      return null; // we'll handle message in UI
    }

    final user = User.fromMap(result.first);

    // 2. Wrong password case handled separately
    if (!PasswordHelper.verifyPassword(password, user.password)) {
      throw Exception("wrong_password");
    }

    return user;
  }

  static Future<User?> getUserById(int id) async {
    final db = await database;

    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);

    if (result.isNotEmpty) {
      return User.fromMap(result.first);
    }
    return null;
  }

  static Future<int> updateUser(User user) async {
    final db = await database;
    final userMap = user.toMap();
    userMap['password'] = PasswordHelper.normalizeForStorage(user.password);

    return await db.update(
      'users',
      userMap,
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // TASKS

  static Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert('tasks', task.toMap());
  }

  static Future<List<Task>> getTasks(int userId) async {
    final db = await database;

    final result = await db.query(
      'tasks',
      where: 'userId = ?',
      whereArgs: [userId],
    );

    return result.map((e) => Task.fromMap(e)).toList();
  }

  static Future<int> updateTask(Task task) async {
    final db = await database;

    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  static Future<int> deleteTask(int id) async {
    final db = await database;

    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> toggleTask(int id, int value) async {
    final db = await database;

    return await db.update(
      'tasks',
      {'isCompleted': value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
