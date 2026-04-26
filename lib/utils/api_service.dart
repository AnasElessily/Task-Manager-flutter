import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/task.dart';

class ApiService {
  static String get rootUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000'; // Special address for Android emulators
    }
    return 'http://localhost:3000'; // Normal address for everything else
  }

  static String get baseUrl => '$rootUrl/api';

  static Future<Map<String, dynamic>> register(User user) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toMap()),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'Could not create account. Maybe that email is already used?',
      );
    }
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'login_failed');
    }
  }

  static Future<bool> syncTasks(int userId, List<Task> tasks) async {
    final List<Map<String, dynamic>> tasksMap = tasks
        .map((t) => t.toMap())
        .toList();

    final response = await http.post(
      Uri.parse('$baseUrl/tasks/sync'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'tasks': tasksMap}),
    );

    return response.statusCode == 200;
  }

  // Requests a list of all tasks for a specific user from the server
  static Future<List<Task>> fetchTasks(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/tasks/$userId'));

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Task.fromMap(json)).toList();
    }
    return [];
  }

  static Future<bool> updateProfile(User user) async {
    final response = await http.put(
      Uri.parse('$baseUrl/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(user.toMap()),
    );
    return response.statusCode == 200;
  }

  static Future<bool> deleteTask(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/tasks/$id'));
    return response.statusCode == 200;
  }

  static Future<bool> toggleFavorite(String id, bool isFavorite) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$id/favorite'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'isFavorite': isFavorite}),
    );
    return response.statusCode == 200;
  }

  static Future<String?> uploadProfileImage(int userId, File imageFile) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/image'),
    );

    request.fields['userId'] = userId.toString();
    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['imageUrl'];
    }
    return null;
  }
}
