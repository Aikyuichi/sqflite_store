// Copyright (c) 2024 Aikyuichi <aikyu.sama@gmail.com>
// All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

library sqflite_store;

import 'package:sqflite/sqflite.dart' show Database;
import 'package:sqflite_store/src/db_asset.dart';
import 'package:sqflite_store/src/db_store.dart';
import 'package:sqflite_store/src/db_updater.dart';

export 'package:sqflite/sqflite.dart' hide openReadOnlyDatabase;
export 'src/sqflite_extension.dart';

/// Adds a database from assets to the repository.
///
/// The default [key] for the database is the name without the extension.
///
/// When copy is set to
/// - 'always': the database is copied from the assets to the repository every time the app is launched.
/// - 'once': the database is copied when the app is launched for the first time or when it doesn't exists.
/// - 'if<{version}': the database is copied from the assets if the database version number is less than {version} number.
/// - 'if>{version}': the database is copied from the assets if the database version number is greater than {version} number.
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
/// If [keyOrPath] is not specified, then the database marked as default is returned or the first one from the repository. If is a key registered in the repository, that database is opened. Otherwise it is treated as the database path.
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

/// Returns the database for the specified [key] from the repository.
///
/// If [key] is not specified, then the database marked as default is returned or the first one from the repository.
Future<Database> getDatabase({String? key}) {
  final dbKey = key ?? DbStore().getDefaultDbKey();
  return DbStore().getDatabase(dbKey);
}

/// Close all the databases of repository.
Future<void> closeDbStore() {
  return DbStore().close();
}

/// Updates the databases specified in the json file of the given [path].
///
/// The default [path] is "assets/updates.json".
Future<void> updateDbStore({String path = 'assets/updates.json'}) {
  return DbUpdater().run(path);
}
