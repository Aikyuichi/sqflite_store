// Copyright (c) 2024 Aikyuichi <aikyu.sama@gmail.com>
// All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'package:flutter/foundation.dart' show kDebugMode, ByteData;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'sqflite_extension.dart';
import 'db_asset.dart';

/// Centralized repository for managing SQLite database assets, active connections, and defaults.
class DbStore {
  final Map<String, DbAsset> _assets = {};
  final Map<String, Future<Database>> _databases = {};
  String _defaultDbKey = '';

  static final DbStore _instance = DbStore.internal();

  /// Returns the singleton instance of [DbStore].
  factory DbStore() => _instance;

  /// Internal constructor for the [DbStore] singleton.
  DbStore.internal();

  /// Adds a database asset to the repository, copying it according to [copy] mode
  /// and configuring optional [attachments], [readonly] status, and [defaultDb] flag.
  Future<void> addAsset(String path, String? key, String copy,
      Map<String, String> attachments, bool readonly, bool defaultDb) async {
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

  /// Retrieves the [DbAsset] configuration associated with the given [key].
  /// Throws an exception if no asset is registered with that key.
  DbAsset getAsset(String key) {
    if (!checkAssetExists(key)) {
      throw _dbNotRegisteredException(key);
    }
    return _assets[key]!;
  }

  /// Returns the active [Database] instance for the specified [key] from the repository,
  /// opening it if necessary.
  Future<Database> getDatabase(String key) async {
    if (!_databases.containsKey(key) || !(await _databases[key]!).isOpen) {
      final dbAsset = getAsset(key);
      _databases[key] = open(dbAsset, dbAsset.readonly);
    }
    return _databases[key]!;
  }

  /// Checks whether a database asset is registered with the given [key].
  bool checkAssetExists(String key) {
    return _assets.containsKey(key);
  }

  /// Returns the key of the default database, or the first registered database key if none is explicitly set.
  String getDefaultDbKey() {
    if (_defaultDbKey.isEmpty && _assets.keys.isNotEmpty) {
      _defaultDbKey = _assets.keys.first;
    }
    return _defaultDbKey;
  }

  /// Closes all active database connections in the repository and clears cache.
  Future<void> close() async {
    final dbKeys = _databases.keys.toList();
    for (var dbKey in dbKeys) {
      final db = await _databases[dbKey]!;
      await db.close();
      _databases.remove(dbKey);
    }
  }

  /// Opens a database for the given [DbAsset] item, attaching any required schemas.
  Future<Database> open(DbAsset item, bool readonly) async {
    final db = await openDatabase(item.targetPath,
        readOnly: readonly, singleInstance: false);
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
        copy = (operation == '<' && targetVersion < sourceVersion) ||
            (operation == '>' && targetVersion > sourceVersion);
      } else {
        copy = true;
      }
    }
    if (copy) {
      try {
        await Directory(dirname(targetPath)).create(recursive: true);
        ByteData data = await rootBundle.load(sourcePath);
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
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
    final attachments = await db.getAttachments();
    return attachments.any((x) => x['name'] == schema);
  }

  void _printDbNotRegistered(String? key) {
    if (kDebugMode) {
      print('there is no database registered with the key: $key');
    }
  }

  Exception _dbNotRegisteredException(String key) {
    return Exception('there is no database registered with the key: $key');
  }
}
