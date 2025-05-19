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
}