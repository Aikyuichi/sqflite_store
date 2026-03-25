# sqflite_store

[![Pub Version](https://img.shields.io/pub/v/sqflite_store)](https://pub.dev/packages/sqflite_store)

Access your SQLite databases easily.

## Getting Started

sqflite_store is available through [pub.dev](https://pub.dev/packages/sqflite_store).

Add the dependency to your pubspec.yaml:

```yaml
dependencies:
  ...
  sqflite_store: ^0.1.0
```

## Usage example

Check the example folder

Register the database in the main.dart
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await registerDbAsset('assets/main.sqlite', key: 'db', copy: 'once', defaultDb: true);

  runApp(const MyApp());
}
```

Get the database using the key.
```dart
final db = await getDatabase(key: 'db');
```
The db object is a instance of [sqflite](https://pub.dev/packages/sqflite) database.