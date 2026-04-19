// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

void main() => runApp(const FirebaseCoreExampleApp());

/// The example app's root widget.
class FirebaseCoreExampleApp extends StatefulWidget {
  /// Creates the example app.
  const FirebaseCoreExampleApp({super.key});

  @override
  State<FirebaseCoreExampleApp> createState() => _FirebaseCoreExampleAppState();
}

class _FirebaseCoreExampleAppState extends State<FirebaseCoreExampleApp> {
  static const String _secondaryName = 'secondary';
  final List<String> _log = <String>[];

  void _appendLog(String line) {
    setState(() {
      _log.insert(0, line);
    });
  }

  Future<void> _initializeDefault() async {
    try {
      final FirebaseApp app = await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _appendLog('Initialized default app: ${app.name}');
    } on FirebaseException catch (error) {
      _appendLog('initializeApp failed: ${error.code} / ${error.message}');
    }
  }

  Future<void> _initializeSecondary() async {
    try {
      final FirebaseApp app = await Firebase.initializeApp(
        name: _secondaryName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _appendLog('Initialized secondary app: ${app.name}');
    } on FirebaseException catch (error) {
      _appendLog('secondary initializeApp failed: ${error.code}');
    }
  }

  void _listApps() {
    final List<String> names =
        Firebase.apps.map((FirebaseApp app) => app.name).toList();
    _appendLog('Registered apps: $names');
  }

  Future<void> _deleteSecondary() async {
    try {
      final FirebaseApp app = Firebase.app(_secondaryName);
      await app.delete();
      _appendLog('Deleted secondary app.');
    } on FirebaseException catch (error) {
      _appendLog('Delete failed: ${error.code}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('firebase_core_tizen example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              ElevatedButton(
                onPressed: _initializeDefault,
                child: const Text('Initialize default app'),
              ),
              ElevatedButton(
                onPressed: _initializeSecondary,
                child: const Text('Initialize secondary app'),
              ),
              ElevatedButton(
                onPressed: _listApps,
                child: const Text('List apps'),
              ),
              ElevatedButton(
                onPressed: _deleteSecondary,
                child: const Text('Delete secondary'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _log.length,
                  itemBuilder: (BuildContext context, int index) =>
                      Text(_log[index]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
