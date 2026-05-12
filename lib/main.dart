import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'dart:math';
import 'models/task.dart';
import 'services/task_local_database.dart';
import 'services/task_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("tasks");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KrakFlow Lab 09',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
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

  int allCount = 0;
  int doneCount = 0;

  @override
  void initState() {
    super.initState();
    _refreshTasks();
  }

  void _refreshTasks() {
    setState(() {
      _tasksFuture = _loadTasks();
    });
  }

  Future<List<Task>> _loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded(); //
    final tasks = TaskLocalDatabase.getTasks();

    setState(() {
      allCount = tasks.length;
      doneCount = tasks.where((t) => t.done).length;
    });

    return tasks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow (Hive DB)"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              await TaskLocalDatabase.deleteAllTasks();
              _refreshTasks();
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Zadania: $allCount | Wykonane: $doneCount", style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _filterButton("Wszystkie", "wszystkie"),
              _filterButton("Do zrobienia", "do zrobienia"),
              _filterButton("Wykonane", "wykonane"),
            ],
          ),
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _tasksFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text("Błąd: ${snapshot.error}"));

                final tasks = snapshot.data ?? [];
                var filteredTasks = tasks;
                if (selectedFilter == "wykonane") filteredTasks = tasks.where((t) => t.done).toList();
                if (selectedFilter == "do zrobienia") filteredTasks = tasks.where((t) => !t.done).toList();

                return ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return Dismissible(
                      key: Key(task.id.toString()),
                      onDismissed: (_) async {
                        await TaskLocalDatabase.deleteTask(task.id);
                        _refreshTasks();
                      },
                      background: Container(color: Colors.red, alignment: Alignment.centerRight, child: const Icon(Icons.delete, color: Colors.white)),
                      child: ListTile(
                        leading: Checkbox(
                          value: task.done,
                          onChanged: (val) async {
                            task.done = val ?? false;
                            await TaskLocalDatabase.updateTask(task); // Zapis do bazy
                            _refreshTasks();
                          },
                        ),
                        title: Text(task.title, style: TextStyle(decoration: task.done ? TextDecoration.lineThrough : null)),
                        subtitle: Text("${task.deadline} | ${task.priority}"),
                        onTap: () async {
                          final updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => EditTaskScreen(task: task)));
                          if (updated != null) {
                            await TaskLocalDatabase.updateTask(updated);
                            _refreshTasks();
                          }
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final newTask = await Navigator.push<Task>(context, MaterialPageRoute(builder: (context) => AddTaskScreen()));
          if (newTask != null) {
            await TaskLocalDatabase.addTask(newTask);
            _refreshTasks();
          }
        },
      ),
    );
  }

  Widget _filterButton(String label, String value) {
    return TextButton(
      onPressed: () => setState(() => selectedFilter = value),
      child: Text(label, style: TextStyle(color: selectedFilter == value ? Colors.deepPurple : Colors.grey)),
    );
  }
}


class AddTaskScreen extends StatelessWidget {
  final tc = TextEditingController();
  final dc = TextEditingController();
  final pc = TextEditingController();

  AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nowe Zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: tc, decoration: const InputDecoration(labelText: "Tytuł")),
            TextField(controller: dc, decoration: const InputDecoration(labelText: "Termin")),
            TextField(controller: pc, decoration: const InputDecoration(labelText: "Priorytet")),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, Task(
                id: Random().nextInt(1000000),
                title: tc.text,
                deadline: dc.text,
                priority: pc.text,
                done: false,
              )),
              child: const Text("Dodaj"),
            )
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final Task task;
  late final tc = TextEditingController(text: task.title);
  late final dc = TextEditingController(text: task.deadline);
  late final pc = TextEditingController(text: task.priority);

  EditTaskScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edytuj Zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: tc, decoration: const InputDecoration(labelText: "Tytuł")),
            TextField(controller: dc, decoration: const InputDecoration(labelText: "Termin")),
            TextField(controller: pc, decoration: const InputDecoration(labelText: "Priorytet")),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, Task(
                id: task.id,
                title: tc.text,
                deadline: dc.text,
                priority: pc.text,
                done: task.done,
              )),
              child: const Text("Zapisz"),
            )
          ],
        ),
      ),
    );
  }
}