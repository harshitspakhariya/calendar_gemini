import 'package:calendar_gemini/constants.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../oauth/google_calendar_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String apiKey = gemini_api_key;
  List<ChatMessage> messages = [];
  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "Gemini");
  GenerativeModel? model;
  GoogleCalendarService googleCalendarService = GoogleCalendarService();

  @override
  void initState() {
    model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Gemini Calendar"),
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    return DashChat(
        currentUser: currentUser, onSend: _sendMessage, messages: messages);
  }

  void _sendMessage(ChatMessage chatMessage) async {
    setState(() {
      messages = [chatMessage, ...messages];
    });

    String getCurrentDateInYYYYMMDD() {
      DateTime now = DateTime.now();
      return DateFormat('yyyy-MM-dd').format(now);
    }

    try {
      String context =
          """  Suppose you are a Google Calendar Scheduler app, and 
                            your task is to classify the user's intent and  
                            provide the relevant event details in JSON format. 
                            Only return the JSON response without extra sentences.
                            Default the year and time fields to the latest logical
                            values if they are missing (e.g., if no year is provided,
                            use the current year unless the date has already passed,
                            in which case use the next year).
                            Here are the Event_Intents you need to classify: 
                            { Add_Event, Shift_Event, Cancel_Event, Add_Recurring_Event,
                             AllDay_Event, Add_Notification }

                            For each intent, return the required fields in the correct JSON format:
                            - If the user doesn't specify a year, assume it's the current year 
                            unless the date has passed, then assume it's the next year.
                            - If no time is provided, default the time to 00:00 
                            for all-day events.""";

      DateTime current = DateTime.now();
      String currentDate = DateFormat('yyyy-MM-dd').format(current);

      String fields = """   Fields required for Add_Event are:
                            {
                              "User_Intent": "Add_Event",
                              "Event_name": "",          // Use a valid event name with all letters in small case.
                              "Date": "YYYY-MM-DD",      // Use format YYYY-MM-DD.
                              "Start_Time": "HH:MM",     // 24-hour format (HH:MM).
                              "End_Time": "HH:MM"        // Optional.
                            }

                            Fields required for Shift_Event are:
                            {
                              "User_Intent": "Shift_Event",
                              "Event_name": "",          // Use a valid event name with all letters in small case.
                              "Date": "YYYY-MM-DD",      // Use format YYYY-MM-DD.
                              "Start_Time": "HH:MM",     // 24-hour format (HH:MM).
                              "End_Time": "HH:MM"        // Optional.
                            }

                            For Cancel_Event if you are not able to extract any 
                            date then by default take the date as null.
                            Fields required for Cancel_Event are:
                            {
                              "User_Intent": "Cancel_Event",
                              "Event_name": "",          // Use a valid event name with all letters in small case.
                              "Date": "YYYY-MM-DD",      // Use format YYYY-MM-DD.
                              "Start_Time": "HH:MM",     // 24-hour format (HH:MM).
                              "End_Time": "HH:MM"        // Optional.
                            }
                              
                            Fields required for Add_Recurring_Event are:
                            {
                              "User_Intent": "Add_Recurring_Event",
                              "Event_name": "",          // Use a valid event name with all letters in small case.
                              "Date": "YYYY-MM-DD",      // Use format YYYY-MM-DD.
                              "Start_Time": "HH:MM",     // 24-hour format (HH:MM).
                              "Recurrence_Frequency": "" // Use only daily, weekly, monthly, annually
                              "End_Time": "HH:MM"        // Optional. 
                            }

                            You must interpret relative dates (e.g., "today", "tomorrow", "next week")
                            correctly based on the current date which is $currentDate. 
                            You must interpret the repeated time terms(e.g., "daily","weekly","monthly","annual")
                            If only the day and month are provided,
                            assume the latest possible future date. 
                            Do not use dates in the past.
                            Return the data in this format for the following user query: """;

      // String ending =
      //     "\n Besides this also act like a normal Gemini Chatbot application";
      String prompt = context + fields + chatMessage.text;

      if (model != null) {
        // Create content for the prompt
        final content = [Content.text(prompt)];
        final response = await model!.generateContent(content);
        String responseText = response.text ?? 'Please ask a proper query';

        try {
          responseText =
              responseText.replaceAll(RegExp(r'```json|```|\njson'), '').trim();
          responseText = responseText.replaceAll('undefined', 'null');
          int jsonEndIndex = responseText.indexOf('}') + 1;
          String jsonString = responseText.substring(0, jsonEndIndex).trim();
          String botReply = responseText.substring(jsonEndIndex).trim();

          print(jsonString);
          Map<String, dynamic> eventData = jsonDecode(jsonString);

          // print(eventData);
          String userIntent = eventData['User_Intent'] ?? 'null';
          String eventDate = eventData['Date'] ?? 'null';
          String startTimeStr = eventData['Start_Time'] ?? 'null';
          String endTimeStr = eventData['End_Time'] ?? 'null';
          String eventName = eventData['Event_name'] ?? 'null';
          String recurrenceFreq = eventData['Recurrence_Frequency'] ?? 'null';

          if (eventName == 'null') {
            eventName = 'No_Title';
          }

          print("User Intent: $userIntent");
          print("Event Date: $eventDate");
          print("Event Start Time: $startTimeStr");
          print("Event End Time: $endTimeStr");
          print("Event Name: $eventName");
          print("Recurrence Frequency: $recurrenceFreq");

          String preMessage = "";

          try {
            if (userIntent == "Add_Event") {
              DateTime startDate = DateTime.parse(eventDate);
              DateTime startTime = DateTime.parse("$eventDate $startTimeStr");
              DateTime endTime = endTimeStr != 'null'
                  ? DateTime.parse("$eventDate $endTimeStr")
                  : startTime.add(Duration(hours: 1));

              await googleCalendarService.addEvent(
                  eventName, startDate, startTime, endTime);
              preMessage = "Event added successfully on your Calendar \n";
            }
          } catch (e) {
            print("Failed to add Event to calendar: $e");
          }

          try {
            if (userIntent == "Shift_Event") {
              DateTime startDate = DateTime.parse(eventDate);
              DateTime startTime = DateTime.parse("$eventDate $startTimeStr");
              DateTime endTime = endTimeStr != 'null'
                  ? DateTime.parse("$eventDate $endTimeStr")
                  : startTime.add(Duration(hours: 1));

              await googleCalendarService.shiftEvent(
                  eventName, startDate, startTime, endTime);
              preMessage = "Event shifted successfully on your Calendar \n";
            }
          } catch (e) {
            print("Failed to shift Event to calendar: $e");
          }

          try {
            if (userIntent == "Cancel_Event") {
              await googleCalendarService.cancelEvent(eventName, eventDate);
              preMessage = "Event removed successfully from your Calendar \n";
            }
          } catch (e) {
            print("Failed to cancel Event on your calendar: $e");
          }

          try {
            if (userIntent == "Add_Recurring_Event") {
              DateTime startDate = DateTime.parse(eventDate);
              DateTime startTime = DateTime.parse("$eventDate $startTimeStr");
              DateTime endTime = endTimeStr != 'null'
                  ? DateTime.parse("$eventDate $endTimeStr")
                  : startTime.add(Duration(hours: 1));    
              String rrule="";

              
              if (recurrenceFreq.toLowerCase() == "daily")
                rrule = "RRULE:FREQ=DAILY";
              else if (recurrenceFreq.toLowerCase() == "monthly")
                rrule = "RRULE:FREQ=MONTHLY";
              else if (recurrenceFreq.toLowerCase() == "weekly")
                rrule = "RRULE:FREQ=WEEKLY";
              else if (recurrenceFreq.toLowerCase() == "yearly")
                rrule = "RRULE:FREQ=YEARLY";

              await googleCalendarService.addRecurringEvent(
                eventName, startDate, startTime, endTime, rrule
              );
              preMessage = "Recurring Event added successfully to your Calendar\n";
              print("Recurring Event added successfully on your calendar\n");
            }
          } catch (e) {
            print("Failed to add recurring Event on your calendar: $e");
          }

          ChatMessage newMessage = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: botReply +
                " \n Details:- \n $preMessage Date: $eventDate, Event: $eventName",
          );
          setState(() {
            messages = [newMessage, ...messages];
          });
        } catch (e) {
          print("Failed to parse JSON response from Gemini: $e");
        }
      }
    } catch (e) {
      print("Failed to retreive the prompt $e");
    }
  }
}
