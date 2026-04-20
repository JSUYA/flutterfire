// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FirebaseAuthExampleApp());
}

/// Example app that exercises the supported firebase_auth_tizen surface.
class FirebaseAuthExampleApp extends StatefulWidget {
  /// Creates the example app.
  const FirebaseAuthExampleApp({super.key});

  @override
  State<FirebaseAuthExampleApp> createState() => _FirebaseAuthExampleAppState();
}

class _FirebaseAuthExampleAppState extends State<FirebaseAuthExampleApp> {
  final List<String> _log = <String>[];
  StreamSubscription<User?>? _authSub;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _currentUser = user;
        _appendLog('authStateChanges: ${user?.uid ?? 'signed-out'}');
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _appendLog(String line) {
    setState(() {
      _log.insert(0, line);
    });
  }

  Future<void> _signInAnonymously() async {
    try {
      final UserCredential credential =
          await FirebaseAuth.instance.signInAnonymously();
      _appendLog('signInAnonymously -> ${credential.user?.uid}');
    } on FirebaseAuthException catch (error) {
      _appendLog('anonymous failed: ${error.code}');
    }
  }

  Future<void> _signInEmailPassword() async {
    try {
      final UserCredential credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: 'demo@flutter-tizen.dev',
        password: 'correct-horse-battery',
      );
      _appendLog('signInEmailPassword -> ${credential.user?.uid}');
    } on FirebaseAuthException catch (error) {
      _appendLog('email sign-in failed: ${error.code}');
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    _appendLog('signOut complete');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('firebase_auth_tizen example')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Current user: ${_currentUser?.uid ?? 'signed-out'}',
                key: const Key('auth-current-user'),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                key: const Key('auth-sign-in-anon'),
                onPressed: _signInAnonymously,
                child: const Text('Sign in anonymously'),
              ),
              ElevatedButton(
                key: const Key('auth-sign-in-email'),
                onPressed: _signInEmailPassword,
                child: const Text('Sign in with email/password'),
              ),
              ElevatedButton(
                key: const Key('auth-sign-out'),
                onPressed: _signOut,
                child: const Text('Sign out'),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _log.length,
                  itemBuilder: (BuildContext context, int index) =>
                      Text(_log[index], key: Key('auth-log-$index')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
