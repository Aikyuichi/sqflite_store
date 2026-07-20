// Copyright (c) 2024 Aikyuichi <aikyu.sama@gmail.com>
// All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

import 'package:sqflite/sqflite.dart';

extension DatabaseExtension on Database {
  Future<void> attach(String filename, String schema) async {
    await rawQuery("ATTACH DATABASE '$filename' AS '$schema'");
  }

  Future<void> detach(String schema) async {
    await rawQuery("DETACH DATABASE '$schema'");
  }

  /// Implementation of PRAGMA: database_list
  ///
  /// Return one row for each database attached to the current database connection.
  Future<List<Map<String, Object?>>> getAttachments() async {
    return await rawQuery('PRAGMA database_list');
  }

  /// Implementation of PRAGMA: foreign_key_check
  ///
  /// Checks the database, or the [table], for foreign key constraints that are violated.
  /// Returns one row for each foreign key violation.
  Future<List<Map<String, Object?>>> checkForeignKeys(
      {String schema = 'main', String? table}) async {
    if (table != null) {
      return await rawQuery('PRAGMA $schema.foreign_key_check($table)');
    }
    return await rawQuery('PRAGMA $schema.foreign_key_check');
  }

  /// Implementation of PRAGMAs: integrity_check, quick_check
  ///
  /// It does a low-level formatting and consistency check of the database.
  /// Return one row for each problem found.
  Future<List<Map<String, Object?>>> checkIntegrity(
      {String schema = 'main',
      String? table,
      int limit = 100,
      bool quick = false}) async {
    if (quick) {
      return rawQuery('PRAGMA $schema.quick_check(${table ?? limit})');
    }
    return rawQuery('PRAGMA $schema.integrity_check(${table ?? limit})');
  }

  /// Implementation of PRAGMA: optimize
  ///
  /// Attempt to optimize the database, or the specified [schema].
  Future<List<Map<String, Object?>>> optimize(
      {String schema = 'main', int? mask}) async {
    return await rawQuery(
        'PRAGMA $schema.optimize${mask != null ? '($mask)' : ''}');
  }

  /// Implementation of PRAGMA: foreign_key_list
  ///
  /// Returns one row for each foreign key constraint of the given [table].
  Future<List<Map<String, Object?>>> getForeignKeys(String table) async {
    return await rawQuery('PRAGMA foreign_key_list($table)');
  }

  /// Implementation of PRAGMA: index_list
  ///
  /// Returns one row for each index associated with the given [table].
  Future<List<Map<String, Object?>>> getIndexes(String table,
      {String schema = 'main'}) async {
    return await rawQuery('PRAGMA $schema.index_list($table)');
  }

  /// Implementation of PRAGMA: index_info
  ///
  /// Returns one row for each key column in the index with the given [name].
  Future<List<Map<String, Object?>>> getIndexInfo(String name,
      {String schema = 'main'}) async {
    return await rawQuery('PRAGMA $schema.index_info($name)');
  }

  /// Implementation of PRAGMA: table_xinfo
  ///
  /// Returns one row for each column in the table with the given [name], including generated columns and hidden columns.
  Future<List<Map<String, Object?>>> getTableInfo(String name,
      {String schema = 'main'}) async {
    return await rawQuery('PRAGMA $schema.table_xinfo($name)');
  }

  /// Implementation of PRAGMA: table_list
  ///
  /// Returns information about the tables and views in the [schema], one table per row.
  Future<List<Map<String, Object?>>> getTables({String schema = 'main'}) async {
    return await rawQuery('PRAGMA $schema.table_list');
  }
}
