import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'task_repository.dart';

class TaskApiService {
  static const String baseUrl = "https://dummyjson.com";

  static Future<List<Task>> fetchTasks() async {
    final response = await http.get(Uri.parse("$baseUrl/todos"));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List todos = data["todos"];

      final random = Random();
      final priorities = ["niski", "średni", "wysoki"];
      final deadlines = ["dziś", "jutro", "za tydzień", "pilne"];
      return todos.map((todo) {
        return Task(
          title: todo["todo"],
          done: todo["completed"],
          deadline: deadlines[random.nextInt(deadlines.length)],
          priority: priorities[random.nextInt(priorities.length)],
        );
      }).toList();
    } else {
      throw Exception("Błąd połączenia: ${response.statusCode}");
    }
  }
}