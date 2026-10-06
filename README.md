# sqflite_store

[![Pub Version](https://img.shields.io/pub/v/sqflite_store)](https://pub.dev/packages/sqflite_store)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A powerful and easy-to-use Flutter package for managing and accessing SQLite databases from assets, handling schema updates, and utilizing helper extensions.

## Features

- **Asset Database Registration**: Easily copy and register SQLite databases bundled in your app assets.
- **Flexible Copy Modes**: Support for copying databases `always`, `once`, or conditionally based on database versions (`if<{version}`, `if>{version}`).
- **Database Repository**: Centralized management of multiple database connections, default databases, and graceful closing.
- **Automated Database Updates**: Run schema and data migration commands defined via JSON configuration (`updateDbStore`).
- **Database Attachments & PRAGMA Extensions**: Convenient extension methods on `Database` for inspecting tables, checking integrity, foreign keys, optimizing, and managing attached databases.

---

## Getting Started

Add `sqflite_store` to your `pubspec.yaml`:

```yaml
dependencies:
  sqflite_store: ^0.3.0
```

Make sure to include your SQLite database files in your assets configuration:

```yaml
flutter:
  assets:
    - assets/main.sqlite
    - assets/updates.json
```

Import the package in your Dart code:

```dart
import 'package:sqflite_store/sqflite_store.dart';
```

---

## Usage Guide

### 1. Registering Database Assets

In your `main()`, initialize Flutter bindings and register your database asset:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await registerDbAsset(
    'assets/main.sqlite',
    key: 'db',
    copy: 'once',       // Options: 'always', 'once', 'if<1', 'if>1'
    defaultDb: true,
  );

  runApp(const MyApp());
}
```

#### Copy Modes (`copy`)
- `'always'`: Copies the database from assets every time the app launches.
- `'once'`: Copies the database only if it does not already exist in the local storage.
- `'if<{version}'`: Copies if the target database version number is less than `{version}`.
- `'if>{version}'`: Copies if the target database version number is greater than `{version}`.

---

### 2. Getting & Opening Databases

Retrieve the registered database instance anywhere in your app:

```dart
// Get the default database
final db = await getDatabase();

// Or get a specific database by key
final analyticsDb = await getDatabase(key: 'analytics');
```

---

### 3. Automated Database Updates (`updateDbStore`)

You can apply schema updates or migrations automatically by providing an updates JSON file (default path: `assets/updates.json`):

```dart
await updateDbStore();
// or custom path:
await updateDbStore(path: 'assets/custom_updates.json');
```

Example `assets/updates.json` structure:
```json
{
  "dbKey": {
    "versions": {
      "2": {
        "commands": [
          "CREATE TABLE IF NOT EXISTS notes (id INTEGER PRIMARY KEY, title TEXT);",
          "ALTER TABLE users ADD COLUMN email TEXT;"
        ],
        "vacuum": true,
        "skipOnError": false
      }
    }
  }
}
```

---

### 4. Database Extensions & PRAGMAs

`sqflite_store` provides rich extension methods on the `Database` class:

- **Attachments**:
  - `await db.attach('path/to/db.sqlite', 'schema_name');`
  - `await db.detach('schema_name');`
  - `await db.getAttachments();`
- **Inspection**:
  - await db.getTables();`
  - `await db.getTableInfo('table_name');`
  - `await db.getIndexes('table_name');`
- **Maintenance**:
  - `await db.checkIntegrity();`
  - `await db.checkForeignKeys();`
  - `await db.optimize();`

---

### Closing Databases

Close all active database connections managed by the store (e.g., when the app pauses or shuts down):

```dart
await closeDbStore();
```

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support & Donations

If you find `sqflite_store` helpful and would like to support its ongoing development and maintenance, consider making a donation:

- **GitHub Sponsors**: [Sponsor @Aikyuichi on GitHub](https://github.com/sponsors/Aikyuichi)
- **Starknet (USDC / ETH / STRK)**: `0x07E42a15Ad7236Ec21CeF4e7d0c353310F76d3D430Fa0E59eb29027a1F7C3A4e`

Your support is greatly appreciated! ❤️