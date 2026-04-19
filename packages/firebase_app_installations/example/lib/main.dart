// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:flutter/material.dart';

void main() => runApp(const InstallationsExampleApp());

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
    final String fid = await FirebaseInstallations.instance.getId();
    setState(() => _fid = fid);
  }

  Future<void> _refreshToken() async {
    final String token =
        await FirebaseInstallations.instance.getToken(true);
    setState(() => _token = token);
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
              Text('FID: $_fid'),
              Text('Token: $_token'),
              ElevatedButton(
                onPressed: _loadFid,
                child: const Text('getId'),
              ),
              ElevatedButton(
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
