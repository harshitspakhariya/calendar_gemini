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
      home: LoginScreen(), // Start with the login screen
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  Future<void> _login() async {
    try {
      bool loggedIn = await _googleAuthService.signInWithGoogle();
      if (loggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage()),
        );
      } else {
        print("Login failed");
      }
    } catch (e) {
      print("Error logging in: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google OAuth Login")),
      body: Center(
        child: ElevatedButton(
          onPressed: _login,
          child: Text("Login with Google"),
        ),
      ),
    );
  }
}
