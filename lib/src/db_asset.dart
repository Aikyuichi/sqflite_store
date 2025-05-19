// Copyright (c) 2024 Aikyuichi <aikyu.sama@gmail.com>
// All rights reserved.
// Use of this source code is governed by a MIT license that can be found in the LICENSE file.

class DbAsset {
  final String sourcePath;
  final String targetPath;
  final String copy;
  final bool readonly;
  final Map<String, String> attachments;

  DbAsset(this.sourcePath, this.targetPath, this.copy, this.readonly, this.attachments);
}