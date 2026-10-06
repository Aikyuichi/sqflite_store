// Copyright (c) 2024 Aikyuichi <aikyu.sama@gmail.com>
// All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

/// A Flutter library for easy management, asset copying, schema migration,
/// and utility extension of SQLite databases using `sqflite`.
library sqflite_store;

import 'package:sqflite/sqflite.dart' show Database;
import 'package:sqflite_store/src/db_asset.dart';
import 'package:sqflite_store/src/db_store.dart';
import 'package:sqflite_store/src/db_updater.dart';

export 'package:sqflite/sqflite.dart' hide openReadOnlyDatabase;
export 'src/sqflite_extension.dart';

/// Registers a database from assets into the database repository.
///
/// The default [key] for the database is the filename without its extension.
///
/// The [copy] parameter controls when the asset is copied to local storage:
/// - `'always'`: The database is copied from assets to the repository every time the app launches.
/// - `'once'`: The database is copied when the app launches for the first time or if the file does not exist.
/// - `'if<{version}'`: The database is copied if the target database version is less than `{version}`.
/// - `'if>{version}'`: The database is copied if the target database version is greater than `{version}`.
///
/// If [defaultDb] is true, this database is marked as the default database when [getDatabase] is called without a key.
Future<void> registerDbAsset(String path,
    {String? key,
    String copy = 'always',
    Map<String, String> attachments = const {},
    bool readonly = false,
    bool defaultDb = false}) {
  return DbStore().addAsset(path, key, copy, attachments, readonly, defaultDb);
}

/// Opens a new connection to the database.
///
/// If [keyOrPath] is not specified, returns the database marked as default or the first one in the repository.
/// If [keyOrPath] matches a registered repository key, that database is opened.
/// Otherwise, it is treated as a direct database file path.
Future<Database> openDatabase({String? keyOrPath, bool? readonly}) {
  final dbKeyOrPath = keyOrPath ?? DbStore().getDefaultDbKey();
  DbAsset dbAsset;
  if (DbStore().checkAssetExists(dbKeyOrPath)) {
    dbAsset = DbStore().getAsset(dbKeyOrPath);
  } else {
    dbAsset = DbAsset(dbKeyOrPath, dbKeyOrPath, '', false, {});
  }
  return DbStore().open(dbAsset, readonly ?? dbAsset.readonly);
}

/// Returns the database instance for the specified [key] from the repository.
///
/// If [key] is not specified, returns the database marked as default or the first one in the repository.
Future<Database> getDatabase({String? key}) {
  final dbKey = key ?? DbStore().getDefaultDbKey();
  return DbStore().getDatabase(dbKey);
}

/// Closes all database connections currently active in the repository.
Future<void> closeDbStore() {
  return DbStore().close();
}

/// Updates the databases specified in the JSON configuration file at the given [path].
///
/// The default [path] is `"assets/updates.json"`.
Future<void> updateDbStore({String path = 'assets/updates.json'}) {
  return DbUpdater().run(path);
}
