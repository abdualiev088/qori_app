import 'package:flutter/material.dart';

void main() {
  runApp(const QoriApp());
}

class QoriApp extends StatelessWidget {
  const QoriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qori',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const Scaffold(),
    );
  }
}
