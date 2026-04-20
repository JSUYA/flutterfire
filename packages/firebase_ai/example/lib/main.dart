// Copyright 2026 Samsung Electronics Co., Ltd. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_ai_tizen/firebase_ai_tizen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FirebaseAiExampleApp());
}

/// Example app demonstrating a Gemini call on Tizen.
class FirebaseAiExampleApp extends StatefulWidget {
  /// Creates the example.
  const FirebaseAiExampleApp({super.key});

  @override
  State<FirebaseAiExampleApp> createState() => _FirebaseAiExampleAppState();
}

class _FirebaseAiExampleAppState extends State<FirebaseAiExampleApp> {
  String _summary = 'press the button to ask Gemini';

  Future<void> _ask() async {
    try {
      final FirebaseAiBackend backend = FirebaseAiTizen.backend();
      final Map<String, Object?> response = await backend.generateContent(
        model: 'gemini-2.5-flash',
        body: <String, Object?>{
          'contents': <Object?>[
            <String, Object?>{
              'parts': <Object?>[
                <String, Object?>{'text': 'What is Tizen in one sentence?'},
              ]
            }
          ]
        },
      );
      setState(() {
        _summary = response.toString();
      });
    } catch (error) {
      setState(() {
        _summary = 'error: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('firebase_ai_tizen')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(_summary, key: const Key('ai-summary')),
              ElevatedButton(
                key: const Key('ai-generate-button'),
                onPressed: _ask,
                child: const Text('generateContent'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
