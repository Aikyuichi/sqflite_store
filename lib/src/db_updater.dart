// Copyright (c) 2024 Aikyuichi <aikyu.sama@gmail.com>
// All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import 'dart:convert';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite/sqflite.dart';
import 'sqflite_extension.dart';
import 'db_store.dart';

class DbUpdater {
  Future<void> run(String path) async {
    final updates = await _getUpdates(path);
    if (updates.isEmpty) {
      return;
    }
    for (var update in updates) {
      var result = await _executeUpdate(update);
      if (!result) {
        if (update.skipOnError) {
          if (kDebugMode) {
            print('update failed but skipped: ${update.toString()}');
          }
        } else {
          if (kDebugMode) {
            print('update failed: ${update.toString()}');
            break;
          }
        }
      }
    }
  }

  Future<List<UpdateItem>> _getUpdates(String filename) async {
    final data = await rootBundle.loadString(filename);
    final Map<String, dynamic> json = jsonDecode(data);
    final updates = <UpdateItem>[];
    for (var key in json.keys) {
      for (var id in json[key]['versions'].keys) {
        updates.add(
            UpdateItem.fromJSON(int.parse(id), key, json[key]['versions'][id]));
      }
    }
    return updates;
  }

  Future<bool> _executeUpdate(UpdateItem update) async {
    var result = false;
    final dbAsset = DbStore().getAsset(update.dbKey);
    final db = await DbStore().open(dbAsset, false);
    for (var attachment in update.attachments) {
      final attachmentAsset = DbStore().getAsset(attachment);
      await db.attach(attachmentAsset.targetPath, attachment);
    }
    try {
      await db.transaction((txn) async {
        final version = await txn.getVersion();
        if (version < update.version) {
          for (var command in update.commands) {
            await txn.execute(command);
          }
          await txn.setVersion(update.version);
        }
        result = true;
      });
      if (update.vacuum) {
        await db.execute('VACUUM');
      }
    } catch (e) {
      if (update.skipOnError) {
        await db.setVersion(update.version);
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
}

class UpdateItem {
  late final Map<String, dynamic> _raw;
  final int version;
  final String dbKey;
  final List<String> commands;
  final List<String> attachments;
  final bool vacuum;
  final bool skipOnError;

  UpdateItem(this.version, this.dbKey, this.commands, this.attachments,
      this.vacuum, this.skipOnError) {
    _raw = {
      'version': version,
      'dbKey': dbKey,
      'commands': commands,
      'attachments': attachments,
      'vacuum': vacuum,
      'skipOnError': skipOnError,
    };
  }

  UpdateItem.fromJSON(this.version, this.dbKey, Map<String, dynamic> json)
      : _raw = json,
        commands = (json['commands'] as List<dynamic>)
            .map((e) => e.toString())
            .toList(),
        attachments = json['attach'] != null
            ? (json['attach'] as List<dynamic>)
                .map((e) => e.toString())
                .toList()
            : [],
        vacuum = json['vacuum'] ?? false,
        skipOnError = json['skipOnError'] ?? false;

  @override
  String toString() {
    return _raw.toString();
  }
}
