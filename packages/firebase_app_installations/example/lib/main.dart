// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const InstallationsExampleApp());
}

/// Example app showing FID + token retrieval.
class InstallationsExampleApp extends StatefulWidget {
  /// Creates the example.
  const InstallationsExampleApp({super.key});

  @override
  State<InstallationsExampleApp> createState() =>
      _InstallationsExampleAppState();
}

class _InstallationsExampleAppState extends State<InstallationsExampleApp> {
  String _fid = 'unknown';
  String _token = 'unknown';

  Future<void> _loadFid() async {
    try {
      final String fid = await FirebaseInstallations.instance.getId();
      setState(() => _fid = fid);
    } catch (error) {
      setState(() => _fid = 'error: $error');
    }
  }

  Future<void> _refreshToken() async {
    try {
      final String token = await FirebaseInstallations.instance.getToken(true);
      setState(() => _token = token);
    } catch (error) {
      setState(() => _token = 'error: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('firebase_app_installations_tizen'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('FID: $_fid', key: const Key('installations-fid')),
              Text('Token: $_token', key: const Key('installations-token')),
              ElevatedButton(
                key: const Key('installations-get-id'),
                onPressed: _loadFid,
                child: const Text('getId'),
              ),
              ElevatedButton(
                key: const Key('installations-get-token'),
                onPressed: _refreshToken,
                child: const Text('getToken(forceRefresh: true)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
