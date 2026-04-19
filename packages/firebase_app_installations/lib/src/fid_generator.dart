// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Generates Firebase Installation IDs (FIDs) following the Firebase JS SDK
/// convention.
///
/// Algorithm (from `firebase-js-sdk/packages/installations/src/util/fid.ts`):
///   1. 17 random bytes from a cryptographically-secure RNG.
///   2. The top nibble of byte 0 is replaced with `0111` so that the base64
///      encoding always starts with one of `c`, `d`, `e`, or `f`.
///   3. base64url-encode (no padding) and take the first 22 characters.
class FidGenerator {
  /// Creates a generator over [random].
  FidGenerator({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  /// Returns a fresh FID.
  String generate() {
    final Uint8List bytes = Uint8List(17);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    bytes[0] = 0x70 | (bytes[0] & 0x0F);
    final String encoded = base64Url.encode(bytes).replaceAll('=', '');
    return encoded.substring(0, 22);
  }

  /// Returns whether [fid] matches the expected Firebase FID regex.
  static bool isValid(String fid) {
    return RegExp(r'^[cdef][A-Za-z0-9_-]{21}$').hasMatch(fid);
  }
}
