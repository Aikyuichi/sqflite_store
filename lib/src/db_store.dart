// Copyright (c) 2024 Aikyuichi <aikyu.sama@gmail.com>
// All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode, ByteData;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'sqflite_extension.dart';
import 'db_asset.dart';
import 'db_update.dart';

/// Databases repository.
class DbStore {
  final Map<String, DbAsset> _assets = {};
  final Map<String, Future<Database>> _databases = {};
  String _defaultDbKey = "";

  static final DbStore _instance = DbStore.internal();

  factory DbStore() => _instance;

  DbStore.internal();

  /// Adds a database from assets to the repository.
  Future<void> registerAsset(String path, String? key, String copy, Map<String, String> attachments, bool readonly, bool defaultDb) async {
    final dbKey = key ?? basenameWithoutExtension(path);
    final targetPath = await _copyAsset(path, copy);
    final item = DbAsset(
      path,
      targetPath,
      copy,
      readonly,
      attachments,
    );
    _assets[dbKey] = item;
    if (defaultDb) {
      _defaultDbKey = dbKey;
    }
  }

  /// Returns the database for the specified [key] from the repository.
  Future<Database> get(String key) {
    if (!_databases.containsKey(key)) {
      if (!_assets.containsKey(key)) {
        _printDbNotRegistered(key);
      }
      final item = _assets[key]!;
      _databases[key] = _open(item, item.readonly);
    }
    return _databases[key]!;
  }

  /// Close all the databases of repository.
  Future<void> close() async {
    for (var database in _databases.values) {
      (await database).close();
    }
  }

  String getDefaultDbKey() {
    if (_defaultDbKey.isEmpty && _assets.keys.isNotEmpty) {
      _defaultDbKey = _assets.keys.first;
    }
    return _defaultDbKey;
  }

  /// Updates the databases specified in the json file of the given [path].
  Future<void> update(String path) async {
    final updates = await _getUpdates(path);
    if (updates.isEmpty) {
      return;
    }
    for (var update in updates) {
      var result = await _executeUpdate(update);
      if (!result) {
        if (update.skipOnError) {
          if (kDebugMode) {
            print('update failed but skipped: $update');
          }
        } else {
          if (kDebugMode) {
            print('update failed: $update');
            break;
          }
        }
      }
    }
  }

  Future<Database> _open(DbAsset item, bool readonly) async {
    final db = await openDatabase(item.targetPath, readOnly: readonly);
    for (var schema in item.attachments.keys) {
      final exists = await _checkSchemaExists(db, schema);
      if (!exists) {
        final dbKey = item.attachments[schema]!;
        if (_assets.containsKey(dbKey)) {
          final dbAsset = _assets[dbKey]!;
          await db.attach(dbAsset.targetPath, schema);
        } else {
          _printDbNotRegistered(dbKey);
        }
      }
    }
    return db;
  }

  Future<String> _copyAsset(String sourcePath, String copyMode) async {
    var databasesPath = await getDatabasesPath();
    var targetPath = join(databasesPath, basename(sourcePath));
    var exists = await databaseExists(targetPath);
    var copy = copyMode == 'always' || (copyMode == 'once' && !exists);
    final ifRegex = RegExp(r'^if([<>])(\d+)$');
    final match = ifRegex.firstMatch(copyMode);
    if (match != null) {
      if (exists) {
        final operation = match.group(1)!;
        final sourceVersion = int.parse(match.group(2)!);
        final db = await openDatabase(targetPath, readOnly: true);
        final targetVersion = await db.getVersion();
        await db.close();
        copy = (operation == '<' && targetVersion < sourceVersion) || (operation == '>' && targetVersion > sourceVersion);
      } else {
        copy = true;
      }
    }
    if (copy) {
      try {
        await Directory(dirname(targetPath)).create(recursive: true);
        ByteData data = await rootBundle.load(sourcePath);
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(targetPath).writeAsBytes(bytes, flush: true);
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
        rethrow;
      }
    }
    return targetPath;
  }

  Future<bool> _checkSchemaExists(Database db, String schema) async {
    try {
      return (await db.rawQuery("SELECT 1 FROM pragma_database_list WHERE name = '$schema'")).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<List<DbUpdate>> _getUpdates(String filename) async {
    final data = await rootBundle.loadString(filename);
    final Map<String, dynamic> json = jsonDecode(data);
    final updates = <DbUpdate>[];
    for (var key in json.keys) {
      for (var id in json[key]['versions'].keys) {
        updates.add(DbUpdate.fromJSON(int.parse(id), key, json[key]['versions'][id]));
      }
    }
    return updates;
  }

  Future<bool> _executeUpdate(DbUpdate update) async {
    var result = false;
    if (!_assets.containsKey(update.dbKey)) {
      _printDbNotRegistered(update.dbKey);
    }
    final dbItem = _assets[update.dbKey]!;
    final db = await _open(dbItem, false);
    for (var attachment in update.attachments) {
      if (_assets.containsKey(attachment)) {
        final attachmentItem = _assets[attachment]!;
        await db.attach(attachmentItem.targetPath, attachment);
      }
    }
    try {
      await db.transaction((txn) async {
        final version = await txn.getVersion();
        if (version < update.version) {
          for (var command in update.commands) {
            await txn.execute(command);
          }
          await txn.execute('PRAGMA user_version = ${update.version}');
        }
        result = true;
      });
      if (update.vacuum) {
        await db.execute('VACUUM');
      }
    } catch (e) {
      if (update.skipOnError) {
        await db.execute('PRAGMA user_version = ${update.version}');
        if (update.vacuum) {
          await db.execute('VACUUM');
        }
      }
      if (kDebugMode) {
        print(e);
      }
    } finally {
      await db.close();
    }
    return result;
  }

  void _printDbNotRegistered(String? key) {
    if (kDebugMode) {
      print('there is no database registered with the key: $key');
    }
  }
}