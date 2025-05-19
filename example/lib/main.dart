import 'package:flutter/material.dart';
import 'package:sqflite_store/sqflite_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await registerDbAsset('assets/main.sqlite', key: 'db', copy: 'once');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Counter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Future<int> _counter = _getCounter();

  @override
  void dispose() {
    closeDbStore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: FutureBuilder<int>(
        future: _counter,
        builder: (builder, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(child: Text('Counter: ${snapshot.data}'));
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _add();
          setState(() {
            _counter = _getCounter();
          });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<int> _getCounter() async {
    final db  = await getDatabase('db');
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT value FROM counter WHERE rowid = 1');
    if (result.isNotEmpty) {
      return result.first['value'];
    }
    return 0;
  }

  Future<void> _add() async {
    final db  = await getDatabase('db');
    await db.rawQuery('UPDATE counter SET value = value + 1 WHERE rowid = 1');
  }
}
