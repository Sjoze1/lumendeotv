import 'package:flutter/material.dart';
import '../pages/Dashboard.dart';
import '../pages/upload.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardPage(),
        '/upload': (context) => const UploadPage(),
      },
    );
  }
}
