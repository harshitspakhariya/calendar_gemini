import 'package:googleapis/calendar/v3.dart' as calendar;
import 'google_auth_service.dart';

class GoogleCalendarService {
  final GoogleAuthService _googleAuthService = GoogleAuthService();

  Future<void> addEvent(String eventName, DateTime startDate, DateTime startTime, DateTime endTime) async {
    var client = await _googleAuthService.getHttpClient();

    if (client == null) {
      print("Failed to authenticate");
      return;
    }

    var calendarApi = calendar.CalendarApi(client);

    // Create the EventDateTime for start and end
    var startDateTime = calendar.EventDateTime()
      ..dateTime = DateTime(
        startDate.year, startDate.month, startDate.day, startTime.hour, startTime.minute)
      ..timeZone = "GMT";  // Use correct timezone if needed

    var endDateTime = calendar.EventDateTime()
      ..dateTime = endTime
      ..timeZone = "GMT";

    // Define the event
    var event = calendar.Event()
      ..summary = eventName
      ..start = startDateTime
      ..end = endDateTime;

    try {
      // Insert event into primary calendar
      var createdEvent = await calendarApi.events.insert(event, 'primary');
      print("Event created: ${createdEvent.htmlLink}");
    } catch (e) {
      print("Error creating event: $e");
    }
  }
}
