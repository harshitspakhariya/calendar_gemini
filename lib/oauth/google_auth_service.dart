import 'package:calendar_gemini/constants.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/calendar'],
    clientId: client_Id
  );

  GoogleSignInAccount? _currentUser;

  Future<bool> signInWithGoogle() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser != null;
    } catch (error) {
      print("Sign-in error: $error");
      return false;
    }
  }

  Future<http.Client?> getHttpClient() async {
      if (_currentUser == null) {
      print("User not signed in");
      bool signedIn = await signInWithGoogle();
      if (!signedIn) {
        print("User sign-in failed");
        return null;  // Sign-in failed
      }
    }

    try {
      GoogleSignInAuthentication auth = await _currentUser!.authentication;

      print("Access Token: ${auth.accessToken}");
      print("ID Token: ${auth.idToken}");

      var client = authenticatedClient(
        http.Client(),
        AccessCredentials(
          AccessToken(
            'Bearer',
            auth.accessToken!,
            DateTime.now().toUtc().add(Duration(hours: 1)), 
          ),
          auth.idToken,
          ['https://www.googleapis.com/auth/calendar'],
        ),
      );
      return client;
    } catch (e) {
      print("Failed to get authenticated client: $e");
      return null;
    }
  }

  String? getProfileImage() {
    return _currentUser?.photoUrl;
  }
  
  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }
}
