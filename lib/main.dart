import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final List<Task> tasks = [
    Task(title: "Przygotować prezentację", deadline: "jutro", done: false, priority: "wysoki"),
    Task(title: "Oddać raport z laboratoriów", deadline: "dzisiaj", done: true, priority: "wysoki"),
    Task(title: "Powtórzyć widgety Flutter", deadline: "w piątek", done: false, priority: "średni"),
    Task(title: "Napisać notatki do kolokwium", deadline: "w weekend", done: false, priority: "niski"),
  ];

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    int doneCount = tasks.where((task) => task.done).length;

    return MaterialApp(
      title: 'KrakFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Scaffold(
        appBar: AppBar(title: const Text("KrakFlow")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sekcja statystyk (Zadanie 5)
              Text(
                "Masz dziś ${tasks.length} zadania, wykonane $doneCount",
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),

              // Nagłówek (Zadanie 3)
              const Text(
                "Dzisiejsze zadania",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Lista zadań
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return TaskCard(
                      title: task.title,
                      subtitle: "termin: ${task.deadline} | priorytet: ${task.priority}",
                      icon: task.done ? Icons.check_circle : Icons.radio_button_unchecked,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Model danych (Zadanie 6)
class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

// Widget TaskCard (Zadanie 4)
class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: icon == Icons.check_circle ? Colors.green : Colors.grey),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
      ),
    );
  }
}