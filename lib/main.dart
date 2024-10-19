import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'pages/home_page.dart'; // Your existing HomePage
import 'oauth/google_auth_service.dart'; // Google OAuth Service
import 'oauth/google_calendar_service.dart'; // Google Calendar Service

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

