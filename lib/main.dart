import 'package:flutter/material.dart';

void main() {
  runApp(const SmartStayApp());
}

class SmartStayApp extends StatelessWidget {
  const SmartStayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '智宿云 SmartStay',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1677FF)),
      ),
      home: const Scaffold(
        body: Center(child: Text('SmartStay C端')),
      ),
    );
  }
}
