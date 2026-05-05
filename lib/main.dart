import 'package:flutter/material.dart';
import 'task_repository.dart';
import 'task_api_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KrakFlow',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedFilter = "wszystkie";
  Future<List<Task>>? _tasksFuture;
  List<Task>? _loadedTasks;

  @override
  void initState() {
    super.initState();
    _tasksFuture = TaskApiService.fetchTasks().then((tasks) {
      _loadedTasks = tasks;
      return tasks;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("KrakFlow")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: FutureBuilder<List<Task>>(
                future: _tasksFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && _loadedTasks == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Błąd: ${snapshot.error}"));
                  }

                  if (_loadedTasks != null) {
                    int doneCount = _loadedTasks!.where((t) => t.done).length;
                    List<Task> displayTasks = _loadedTasks!;

                    if (selectedFilter == "wykonane") {
                      displayTasks = _loadedTasks!.where((t) => t.done).toList();
                    } else if (selectedFilter == "do zrobienia") {
                      displayTasks = _loadedTasks!.where((t) => !t.done).toList();
                    }

                    return Column(
                      children: [
                        Text("Maszdziś ${_loadedTasks!.length} zadań, wykonane $doneCount"),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _filterButton("Wszystkie", "wszystkie"),
                            _filterButton("Do zrobienia", "do zrobienia"),
                            _filterButton("Wykonane", "wykonane"),
                          ],
                        ),
                        Expanded(
                          child: ListView.builder(
                            itemCount: displayTasks.length,
                            itemBuilder: (context, index) {
                              final task = displayTasks[index];
                              return Dismissible(
                                key: ObjectKey(task),
                                onDismissed: (direction) {
                                  setState(() {
                                    _loadedTasks!.remove(task);
                                  });
                                },
                                background: Container(color: Colors.red),
                                child: TaskCard(
                                  title: task.title,
                                  subtitle: "termin: ${task.deadline} | priorytet: ${task.priority}",
                                  done: task.done,
                                  onChanged: (val) {
                                    setState(() {
                                      task.done = val!;
                                    });
                                  },
                                  onTap: () async {
                                    final updatedTask = await Navigator.push<Task>(
                                      context,
                                      MaterialPageRoute(builder: (context) => EditTaskScreen(task: task)),
                                    );
                                    if (updatedTask != null) {
                                      setState(() {
                                        int taskIndex = _loadedTasks!.indexOf(task);
                                        _loadedTasks![taskIndex] = updatedTask;
                                      });
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  }
                  return const Center(child: Text("Brak danych"));
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTask = await Navigator.push<Task>(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => AddTaskScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                final tween = Tween(begin: begin, end: end);
                final offsetAnimation = animation.drive(tween);
                return SlideTransition(position: offsetAnimation, child: child);
              },
            ),
          );
          if (newTask != null) {
            setState(() {
              _loadedTasks?.add(newTask);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterButton(String label, String value) {
    return TextButton(
      onPressed: () => setState(() => selectedFilter = value),
      child: Text(label, style: TextStyle(
        color: selectedFilter == value ? Colors.deepPurple : Colors.grey,
        fontWeight: selectedFilter == value ? FontWeight.bold : FontWeight.normal,
      )),
    );
  }
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(value: done, onChanged: onChanged),
        title: Text(
          title,
          style: TextStyle(
            decoration: done ? TextDecoration.lineThrough : TextDecoration.none,
            color: done ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});
  final titleController = TextEditingController();
  final deadlineController = TextEditingController();
  final priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nowe zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Tytuł", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: deadlineController, decoration: const InputDecoration(labelText: "Termin", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: priorityController, decoration: const InputDecoration(labelText: "Priorytet", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  priority: priorityController.text,
                  done: false,
                );
                Navigator.pop(context, newTask);
              },
              child: const Text("Zapisz"),
            )
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatefulWidget {
  final Task task;
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController deadlineController;
  late TextEditingController priorityController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    deadlineController = TextEditingController(text: widget.task.deadline);
    priorityController = TextEditingController(text: widget.task.priority);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edytuj zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Tytuł", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: deadlineController, decoration: const InputDecoration(labelText: "Termin", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(controller: priorityController, decoration: const InputDecoration(labelText: "Priorytet", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final updatedTask = Task(
                  title: titleController.text,
                  deadline: deadlineController.text,
                  priority: priorityController.text,
                  done: widget.task.done,
                );
                Navigator.pop(context, updatedTask);
              },
              child: const Text("Zapisz zmiany"),
            )
          ],
        ),
      ),
    );
  }
}