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

/// Databases repository.
class DbStore {
  final Map<String, DbAsset> _assets = {};
  final Map<String, Future<Database>> _databases = {};
  String _defaultDbKey = '';

  static final DbStore _instance = DbStore.internal();

  factory DbStore() => _instance;

  DbStore.internal();

  /// Adds a database from assets to the repository.
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

  DbAsset getAsset(String key) {
    if (!checkAssetExists(key)) {
      throw _dbNotRegisteredException(key);
    }
    return _assets[key]!;
  }

  /// Returns the database for the specified [key] from the repository.
  Future<Database> getDatabase(String key) async {
    if (!_databases.containsKey(key) || !(await _databases[key]!).isOpen) {
      final dbAsset = getAsset(key);
      _databases[key] = open(dbAsset, dbAsset.readonly);
    }
    return _databases[key]!;
  }

  bool checkAssetExists(String key) {
    return _assets.containsKey(key);
  }

  String getDefaultDbKey() {
    if (_defaultDbKey.isEmpty && _assets.keys.isNotEmpty) {
      _defaultDbKey = _assets.keys.first;
    }
    return _defaultDbKey;
  }

  /// Close all databases in the repository.
  Future<void> close() async {
    final dbKeys = _databases.keys.toList();
    for (var dbKey in dbKeys) {
      final db = await _databases[dbKey]!;
      await db.close();
      _databases.remove(dbKey);
    }
  }

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
