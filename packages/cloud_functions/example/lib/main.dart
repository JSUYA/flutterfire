// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:core';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

String kEmulatorHost = DefaultFirebaseOptions.emulatorHost;
const bool kUseFunctionsEmulator = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // You should have the Functions Emulator running locally to use it
  // https://firebase.google.com/docs/functions/local-emulator
  if (kUseFunctionsEmulator && defaultTargetPlatform != TargetPlatform.linux) {
    FirebaseFunctions.instance.useFunctionsEmulator(kEmulatorHost, 5001);
  }

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List fruit = [];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Firebase Functions Example'),
        ),
        body: Center(
          child: Column(
            children: <Widget>[
              if (!kUseFunctionsEmulator)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'This example calls a deployed function by default. '
                    'The local Functions emulator is unsupported on Tizen.',
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: fruit.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('${fruit[index]}',
                          key: Key('functions-item-$index')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton.extended(
            key: const Key('functions-call-button'),
            onPressed: () async {
              // See index.js in .github/workflows/scripts for the example function we
              // are using for this example
              HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
                'listFruit',
                options: HttpsCallableOptions(
                  timeout: const Duration(seconds: 5),
                ),
              );

              try {
                final result = await callable();
                setState(() {
                  fruit.clear();
                  result.data.forEach((f) {
                    fruit.add(f);
                  });
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ERROR: $e'),
                  ),
                );
              }
            },
            label: const Text('Call Function'),
            icon: const Icon(Icons.cloud),
            backgroundColor: Colors.deepOrange,
          ),
        ),
      ),
    );
  }
}
