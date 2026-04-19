// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

void main() => runApp(const RemoteConfigExampleApp());

/// Example app demonstrating fetch / activate / get.
class RemoteConfigExampleApp extends StatefulWidget {
  /// Creates the example.
  const RemoteConfigExampleApp({super.key});

  @override
  State<RemoteConfigExampleApp> createState() => _RemoteConfigExampleAppState();
}

class _RemoteConfigExampleAppState extends State<RemoteConfigExampleApp> {
  String _greeting = '(defaults not loaded yet)';

  Future<void> _refresh() async {
    final FirebaseRemoteConfig rc = FirebaseRemoteConfig.instance;
    await rc.setDefaults(<String, Object?>{'greeting': 'Hi from Tizen'});
    await rc.fetchAndActivate();
    setState(() => _greeting = rc.getString('greeting'));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('firebase_remote_config_tizen'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('greeting: $_greeting'),
              ElevatedButton(
                onPressed: _refresh,
                child: const Text('fetchAndActivate()'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
