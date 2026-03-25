// Copyright (c) 2024 Aikyuichi <aikyu.sama@gmail.com>
// All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

library sqflite_store;

import 'package:sqflite/sqflite.dart';
import 'package:sqflite_store/src/db_store.dart';

export 'package:sqflite/sqflite.dart';
export 'src/sqflite_extension.dart';

/// Adds a database from assets to the repository.
///
/// the default [key] for the database is the name without the extension.
/// When copy is set to
/// - 'always': the database is copied from the assets to the repository every time the app is launched.
/// - 'once': the database is copied when the app is launched for the first time or when it doesn't exists.
Future<void> registerDbAsset(String path,
    {String? key,
    String copy = 'always',
    Map<String, String> attachments = const {},
    bool readonly = false,
    bool defaultDb = false}) {
  return DbStore().registerAsset(path, key, copy, attachments, readonly, defaultDb);
}

/// Returns the database for the specified [key] from the repository.
/// if [key] is not specified, then the database marked as default is returned or the first one from the repository.
Future<Database> getDatabase({String? key}) {
  final dbKey = key ?? DbStore().getDefaultDbKey();
  return DbStore().get(dbKey);
}

/// Close all the databases of repository.
Future<void> closeDbStore() {
  return DbStore().close();
}

/// Updates the databases specified in the json file of the given [path].
///
/// the default [path] is "assets/updates.json".
Future<void> updateDbStore({String path = 'assets/updates.json'}) {
  return DbStore().update(path);
}
