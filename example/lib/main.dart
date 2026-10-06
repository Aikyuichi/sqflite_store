import 'package:flutter/material.dart';
import 'package:sqflite_store/sqflite_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Register database asset with sqflite_store
  await registerDbAsset(
    'assets/main.sqlite',
    key: 'db',
    copy: 'once',
    defaultDb: true,
  );

  runApp(const SqlfliteStoreExampleApp());
}

class SqlfliteStoreExampleApp extends StatelessWidget {
  const SqlfliteStoreExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'sqflite_store Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'sqflite_store Demo'),
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
  late final AppLifecycleListener _lifecycle;
  Future<Map<String, dynamic>> _dbInfo = Future.value({});

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: () {
        closeDbStore();
      },
    );
    _loadDatabaseInfo();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _loadDatabaseInfo() async {
    setState(() {
      _dbInfo = _fetchDbInfo();
    });
  }

  Future<Map<String, dynamic>> _fetchDbInfo() async {
    final db = await getDatabase(key: 'db');
    
    // Counter value
    int counter = 0;
    final counterResult = await db.rawQuery('SELECT value FROM counter WHERE rowid = 1');
    if (counterResult.isNotEmpty) {
      counter = counterResult.first['value'] as int;
    }

    // Database version
    final version = await db.getVersion();

    // Tables using DatabaseExtension PRAGMA
    final tables = await db.getTables();

    // Integrity check using DatabaseExtension PRAGMA
    final integrity = await db.checkIntegrity(quick: true);

    return {
      'counter': counter,
      'version': version,
      'tables': tables,
      'integrity': integrity,
    };
  }

  Future<void> _incrementCounter() async {
    final db = await getDatabase();
    await db.rawQuery('UPDATE counter SET value = value + 1 WHERE rowid = 1');
    await _loadDatabaseInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDatabaseInfo,
            tooltip: 'Refresh DB Info',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dbInfo,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data ?? {};
          final counter = data['counter'] ?? 0;
          final version = data['version'] ?? 0;
          final tables = (data['tables'] as List<Map<String, Object?>>?) ?? [];
          final integrity = (data['integrity'] as List<Map<String, Object?>>?) ?? [];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Database Status',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      Text('Database Version: $version'),
                      Text('Integrity Status: ${integrity.isNotEmpty ? integrity.first.values.join(', ') : 'OK'}'),
                      const SizedBox(height: 12),
                      Center(
                        child: Column(
                          children: [
                            const Text('Counter Value from DB:'),
                            Text(
                              '$counter',
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tables in Database (PRAGMA table_list):',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...tables.map((table) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.table_chart),
                      title: Text('${table['name']}'),
                      subtitle: Text('Type: ${table['type']} | Schema: ${table['schema']}'),
                    ),
                  )),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
