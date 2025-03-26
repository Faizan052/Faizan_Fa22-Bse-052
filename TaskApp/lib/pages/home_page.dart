import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/task_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/task_list.dart';
import '../widgets/add_task_dialog.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Today', 'Completed', 'Repeatable'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    await ref.read(tasksProvider.notifier).loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final tasksAsync = ref.watch(tasksProvider);

    return settingsAsync.when(
      data: (settings) => tasksAsync.when(
        data: (tasks) => Scaffold(
          appBar: AppBar(
            title: Text(
              'Smart Task Manager',
              style: TextStyle(fontSize: settings.fontSize * 1.2),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
          body: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                labelStyle: TextStyle(
                  fontSize: settings.fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    TaskList(
                      tasks: tasks.tasks,
                      title: 'Today\'s Tasks',
                      showProgress: settings.fullScreenProgress,
                    ),
                    TaskList(
                      tasks: tasks.completedTasks,
                      title: 'Completed Tasks',
                      showProgress: false,
                    ),
                    Column(
                      children: [
                        TaskList(
                          tasks: tasks.repeatableTasks,
                          title: 'Repeatable Tasks',
                          showProgress: false,
                        ),
                        if (tasks.repeatableTasks.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(tasksProvider.notifier)
                                    .regenerateRepeatableTasks();
                              },
                              child: Text(
                                'Regenerate Tasks',
                                style: TextStyle(fontSize: settings.fontSize),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const AddTaskDialog(),
              );
            },
            child: const Icon(Icons.add),
          ),
        ),
        loading: () => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Scaffold(
          body: Center(
            child: Text('Error: $error'),
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}