import 'package:chicken_dilivery/pages/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // add
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'database/database_helper.dart'; // ADD

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (!kIsWeb) {
    final db = await DatabaseHelper.instance.database;
    print(
      '[APP] DB opened. Tables: ${await DatabaseHelper.instance.getAllTableNames()}',
    );
  } else {
    print('[APP] Web runtime detected. Skipping native SQLite init.');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chicken Sales',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(),
      home: const DashboardPage(),
      // home: const Printpage(),
    );
  }
}
