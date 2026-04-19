// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
//
// Cross-plugin harness: instantiates every Tizen Firebase plugin at once to
// verify the shared runtime and to give CI a realistic worst-case TPK to
// measure. The UI is intentionally minimal — the actual exercising happens
// in the integration_test/ suite.

import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FlutterFireTizenTestsApp());
}

/// Root widget for the combined-use harness.
class FlutterFireTizenTestsApp extends StatelessWidget {
  /// Creates the harness app.
  const FlutterFireTizenTestsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('FlutterFire Tizen tests')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Registered apps: ${Firebase.apps.map((FirebaseApp app) => app.name).toList()}',
              ),
              const SizedBox(height: 8),
              FutureBuilder<String>(
                future: FirebaseInstallations.instance.getId(),
                builder: (BuildContext context, AsyncSnapshot<String> snap) {
                  return Text('FID: ${snap.data ?? '...'}');
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseRemoteConfig.instance
                      .setDefaults(<String, Object?>{'greeting': 'hi'});
                  await FirebaseRemoteConfig.instance.fetchAndActivate();
                },
                child: const Text('fetchAndActivate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
