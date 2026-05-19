import 'package:flutter/material.dart';
import 'task_repository.dart';
import 'package:flutter/material.dart';
import 'task_api_service.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'task_local_database.dart';
import 'task_sync_service.dart';
import 'dart:math';


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
      title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
      ),
      home: HomeScreen(),
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

  Key listKey = UniqueKey();

  int allTasksCount = 0;
  int doneTasksCount = 0;
  int todoTasksCount = 0;

  void updateCounters(List<Task> tasks) {
    setState(() {
      allTasksCount = tasks.length;
      doneTasksCount = tasks.where((task) => task.done).length;
      todoTasksCount = tasks.where((task) => !task.done).length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("KrakFlow"),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: TaskLocalDatabase.isEmpty()
              ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Lista jest pusta")),
              );
            }
            : () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Potwierdzenie"),
                    content: Text(
                        "Czy na pewno chcesz usunąć wszystkie zadania?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Anuluj"),
                      ),
                      TextButton(
                        onPressed: () async {
                          await TaskLocalDatabase.deleteAllTasks();

                          setState(() {
                            listKey = UniqueKey();

                            allTasksCount = 0;
                            doneTasksCount = 0;
                            todoTasksCount = 0;
                          });
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Usunieto wszystkie zadania.")),
                          );
                        },
                        child: Text("Usuń"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Masz dziś $allTasksCount zadania. Ilosc wykonanych zadan: $doneTasksCount"),
            const SizedBox(height: 16),
            const Text("Dzisiejsze zadania",
              style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              ),
            ),

            FilterBar(
              selectedFilter: selectedFilter,
              onFilterChanged: (String newValue) {
                setState(() {
                  selectedFilter = newValue;
                });
              },
            ),

            Expanded(
                child: TaskListScreen(
                  key: listKey,
                  selectedFilter: selectedFilter,
                  onTasksLoaded: updateCounters,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => AddTaskScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final offsetAnimation = Tween<Offset>(
                  begin: Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(animation);
                return SlideTransition(
                  position: offsetAnimation,
                  child: child,
                );
              },
            ),
          );
          if (newTask != null) {
            await TaskLocalDatabase.addTask(newTask);
            setState(() {
              listKey = UniqueKey();
            });
          }
        },
        child: Icon(Icons.add),
      ),
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              onTap: onTap,
              leading: Checkbox(
                value: done,
                onChanged: onChanged,
                activeColor: Colors.pinkAccent,
              ),
              title: Text(
                title,
                style: TextStyle(
                  decoration: done
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                ),
              ),
              subtitle: Text(subtitle),
              trailing: Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }
}


class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});
  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nowe zadanie"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            TextField(
              controller: priorityController,
              decoration: InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  id: Random().nextInt(1000000),
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: false,
                  priority: priorityController.text,
                );
                Navigator.pop(context, newTask);
              },
              child: Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatelessWidget {
  final Task task;
  final TextEditingController titleController;
  final TextEditingController deadlineController;
  final TextEditingController priorityController;

  EditTaskScreen({super.key, required this.task})
      : titleController = TextEditingController(text: task.title),
        deadlineController = TextEditingController(text: task.deadline),
        priorityController = TextEditingController(text: task.priority);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edytuj zadanie"),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            TextField(
              controller: deadlineController,
              decoration: InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),

            TextField(
              controller: priorityController,
              decoration: InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                final updateTask = Task(
                  id: task.id,
                  title: titleController.text,
                  deadline: deadlineController.text,
                  done: task.done,
                  priority: priorityController.text,
                );
                Navigator.pop(context, updateTask);
              },
              child: Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const FilterBar({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: () => onFilterChanged("wszystkie"),
          style: TextButton.styleFrom(
            foregroundColor: selectedFilter == "wszystkie" ? Colors.pinkAccent : Colors.grey,
          ),
          child: Text("Wszystkie"),
        ),
        TextButton(
          onPressed: () => onFilterChanged("do zrobienia"),
          style: TextButton.styleFrom(
            foregroundColor: selectedFilter == "do zrobienia" ? Colors.pinkAccent : Colors.grey,
          ),
          child: Text("Do zrobienia"),
        ),
        TextButton(
          onPressed: () => onFilterChanged("wykonane"),
          style: TextButton.styleFrom(
            foregroundColor: selectedFilter == "wykonane" ? Colors.pinkAccent : Colors.grey,
          ),
          child: Text("Wykonane"),
        ),
      ],
    );
  }
}

class TaskListScreen extends StatefulWidget {
  final ValueChanged<List<Task>> onTasksLoaded;
  final String selectedFilter;

  const TaskListScreen({
    super.key,
    required this.onTasksLoaded,
    required this.selectedFilter,
  });

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = loadTasks();
  }

  Future<List<Task>> loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    return TaskLocalDatabase.getTasks();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: tasksFuture,
      builder: (context, snapshot) {
        // ładowanie
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        // errorr
        if (snapshot.hasError) {
          return Center(
            child: Text("Błąd: ${snapshot.error}"),
          );
        }

        // wszystko okej
        final tasks = snapshot.data  ?? [];

        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onTasksLoaded(tasks);
        });

        List<Task> filteredTasks = tasks;
        if (widget.selectedFilter == "wykonane") {
        filteredTasks = tasks
            .where((task) => task.done)
            .toList();
        } else if (widget.selectedFilter == "do zrobienia") {
        filteredTasks = tasks
            .where((task) => !task.done)
            .toList();
        }

        return ListView.builder(
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];

              return Dismissible(
                key: ValueKey(task.title),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) async {
                  await TaskLocalDatabase.deleteTask(task.id);

                  setState(() {
                  tasksFuture = loadTasks();
                  });

                  // rozszerzenie - wyświetlanie nazwy zadania po usutnięciu
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Zadanie '${task.title}' zostało usunięte."),
                    ),
                  );
                },
                child: TaskCard(
                  title: task.title,
                  subtitle: "termin: ${task.deadline} | priorytet: ${task.priority}",
                  done: task.done,
                  // po kliknieciu
                  onChanged: (value) async {
                    final updatedTask = Task(
                      id: task.id,
                      title: task.title,
                      deadline: task.deadline,
                      priority: task.priority,
                      done: value ?? false,
                    );
                    await TaskLocalDatabase.updateTask(updatedTask);
                    setState(() {
                      tasksFuture = loadTasks();
                    });
                  },
                  // edytowanie
                  onTap: () async {
                    final Task? updatedTask = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTaskScreen(task: task),
                      ),
                    );
                    // aktualizacja po edycji
                    if (updatedTask != null) {
                      await TaskLocalDatabase.updateTask(updatedTask);
                      setState(() {
                        tasksFuture = loadTasks();
                      });
                    }
                  },
                ),
              );
          },
        );
      },
    );
  }
}





