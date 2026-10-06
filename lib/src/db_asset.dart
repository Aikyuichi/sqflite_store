// Copyright (c) 2024 Aikyuichi <aikyu.sama@gmail.com>
// All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

/// Represents an SQLite database asset configuration to be registered and copied locally.
class DbAsset {
  /// The asset path of the source database file (e.g., 'assets/main.sqlite').
  final String sourcePath;

  /// The local target file path where the database is copied.
  final String targetPath;

  /// The copy strategy mode ('always', 'once', 'if<v', 'if>v').
  final String copy;

  /// Whether the database is opened in read-only mode.
  final bool readonly;

  /// Attached database schemas mapped by schema name to database key.
  final Map<String, String> attachments;

  /// Creates a [DbAsset] instance with the specified configuration.
  DbAsset(this.sourcePath, this.targetPath, this.copy, this.readonly,
      this.attachments);
}
