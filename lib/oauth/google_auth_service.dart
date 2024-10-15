import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class GoogleAuthService {
  final List<String> _scopes = ['https://www.googleapis.com/auth/calendar'];

  Future<http.Client?> getHttpClient() async {
    GoogleSignInAccount? account = await GoogleSignIn(scopes: _scopes).signIn();

    if (account == null) {
      return null; // User cancelled the sign-in.
    }

    GoogleSignInAuthentication auth = await account.authentication;

    final accessToken = AccessToken('Bearer', auth.accessToken!, DateTime.now().add(Duration(hours: 1)));

    var authClient = authenticatedClient(http.Client(), AccessCredentials(
      accessToken,
      auth.idToken,
      _scopes,
    ));

    return authClient;
  }
}
