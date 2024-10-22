import 'package:flutter/material.dart';
import 'pages/home_page.dart'; // Your existing HomePage

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gemini Calendar Scheduler',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(), // Start with the login screen
    );
  }
}
