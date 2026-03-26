import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

List<Task> tasks = [
  Task(title: "Zadanie1", deadline: "cz1"),
  Task(title: "Zadanie2", deadline: "cz2"),
  Task(title: "Zadanie3", deadline: "cz3"),
  Task(title: "Zadanie4", deadline: "cz4")
];

class MyApp extends StatelessWidget {
  const MyApp({super.key});



  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Column(
        children: [
          Text("Masz dziś ${tasks.length} zadania"),
          SizedBox(height: 16),
          Text("Dzisiejsze zadania",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),),
          Expanded(child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                return TaskCard(
                    title: tasks[index].title,
                    subtitle: tasks[index].deadline,
                    icon: tasks[index].icon);
                    }))
        ],
      )
    );
  }
}

class Task{
  final String title;
  final String deadline;
  final IconData icon = Icons.one_x_mobiledata_rounded;
  final bool done;

  Task({required this.title, required this.deadline, required this.done});
}

class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
