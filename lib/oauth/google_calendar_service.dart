import 'package:googleapis/calendar/v3.dart' as calendar;
import 'google_auth_service.dart';
import 'package:http/http.dart' as http;

class GoogleCalendarService {
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  // Updated method to accept eventName, startDate, startTime, and endTime
  Future<void> addEvent(String eventName, DateTime startDate, DateTime startTime, DateTime endTime) async {
    http.Client? client = await _googleAuthService.getHttpClient();
    if (client == null) {
      print("Failed to authenticate");
      return;
    }

    var calendarApi = calendar.CalendarApi(client);

    // Adjusting the start and end times to include the date with proper time.
    var eventStart = DateTime(
      startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute
    );
    var eventEnd = DateTime(
      startDate.year, startDate.month, startDate.day, endTime.hour, endTime.minute
    );

    var event = calendar.Event()
      ..summary = eventName
      ..start = calendar.EventDateTime(
        dateTime: eventStart,
        timeZone: "IST",  // Replace with appropriate time zone
      )
      ..end = calendar.EventDateTime(
        dateTime: eventEnd,
        timeZone: "IST",  // Replace with appropriate time zone
      );

    try {
      var createdEvent = await calendarApi.events.insert(event, 'primary');
      print("Event created: ${createdEvent.htmlLink}");
    } catch (e) {
      print("Error creating event: $e");
    }
  }
}
