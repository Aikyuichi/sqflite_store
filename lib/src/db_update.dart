// Copyright (c) 2024 Aikyuichi <aikyu.sama@gmail.com>
// All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

class DbUpdate {
  final int version;
  final String dbKey;
  final List<String> commands;
  final List<String> attachments;
  final bool vacuum;
  final bool skipOnError;

  DbUpdate(this.version, this.dbKey, this.commands, this.attachments, this.vacuum, this.skipOnError);

  DbUpdate.fromJSON(this.version, this.dbKey, Map<String, dynamic> json) :
        commands = (json['commands'] as List<dynamic>).map((e) => e.toString()).toList(),
        attachments = json['attach'] != null ? (json['attach'] as List<dynamic>).map((e) => e.toString()).toList() : [],
        vacuum = json['vacuum'] ?? false,
        skipOnError = json['skipOnError'] ?? false;
}