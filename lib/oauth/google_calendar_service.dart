import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'google_auth_service.dart';

class GoogleCalendarService {
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  Future<void> listEvents() async {
    String? accessToken = await _googleAuthService.getAuthToken();

    if (accessToken != null) {
      // Create an authenticated client
      var authClient = authenticatedClient(http.Client(), AccessCredentials(
        AccessToken('Bearer', accessToken, DateTime.now().add(Duration(hours: 1))),
        null,  // No refresh token available for now
        ['https://www.googleapis.com/auth/calendar.events'],
      ));

      var calendarApi = calendar.CalendarApi(authClient);

      // Retrieve the list of calendar events
      var events = await calendarApi.events.list('primary');

      print("Upcoming events:");
      if (events.items != null) {
        events.items!.forEach((event) {
          print(event.summary);
        });
      }
    } else {
      print("Failed to authenticate.");
    }
  }

  Future<void> createEvent(String summary, DateTime startTime, DateTime endTime) async {
    String? accessToken = await _googleAuthService.getAuthToken();

    if (accessToken != null) {
      // Create an authenticated client
      var authClient = authenticatedClient(http.Client(), AccessCredentials(
        AccessToken('Bearer', accessToken, DateTime.now().add(Duration(hours: 1))),
        null,  // No refresh token available for now
        ['https://www.googleapis.com/auth/calendar.events'],
      ));

      var calendarApi = calendar.CalendarApi(authClient);

      var event = calendar.Event()
        ..summary = summary
        ..start = (calendar.EventDateTime()
          ..dateTime = startTime
          ..timeZone = "GMT")
        ..end = (calendar.EventDateTime()
          ..dateTime = endTime
          ..timeZone = "GMT");

      var createdEvent = await calendarApi.events.insert(event, 'primary');
      print("Event created: ${createdEvent.htmlLink}");
    } else {
      print("Failed to authenticate.");
    }
  }
}
