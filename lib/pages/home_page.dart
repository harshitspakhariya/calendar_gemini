import 'package:calendar_gemini/constants.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../oauth/google_auth_service.dart';
import '../oauth/google_calendar_service.dart';
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
    return DashChat(currentUser: currentUser, onSend: _sendMessage, messages: messages);
  }

  void _sendMessage(ChatMessage chatMessage) async{
    setState(() {
      messages = [chatMessage, ...messages];
    });
    try {
      String context = """Suppose you are a Google Calendar Scheduler app and you have 
                          to help me in classifying the intent of the user with his query 
                          and just return the following data User_Intent, Date, Start_Time, End_Time, Event_name
                          in correct JSON Format from the user's query and by default take value of 
                          all fields as null and don't ask back any questions. Here is the list of 
                          Event_Intents from which you have to classify :-
                          { Add_Event, Shift_Event, Cancel_Event, Add_Recurring_Event, AllDay_Event, 
                          Add_Notification}.Now for every different Intent you have to get the required fields
                          corresponding to that Intent.
                          Fields required for Add_Event are: 
                          {
                            "User_Intent": "Add_Event",
                            "Event_name": "meeting with kavya",     // Use a valid event name, no 'undefined'.
                            "Date": "2024-10-16",                  // Use format YYYY-MM-DD. No 'undefined'.
                            "Start_Time": "17:00",                 // Use 24-hour format for time (HH:MM). No 'undefined'.
                            "End_Time": "18:00"                    // Optional field. No 'undefined', but it's ok if absent.
                          }
                          Fields required for Shift_Event are: 
                          {
                            "User_Intent": "Shift_Event",
                            "Event_name": "meeting with kavya",     // Use a valid event name, no 'undefined'.
                            "Date": "2024-10-16",                  // Use format YYYY-MM-DD. No 'undefined'.
                            "Start_Time": "17:00",                 // Use 24-hour format for time (HH:MM). No 'undefined'.
                            "End_Time": "18:00"                    // Optional field. No 'undefined', but it's ok if absent.
                          }
                          Also try to get the details for the query if the user tells dates in format of today, tomorrow etc.
                          Return the data for the following user query:- """;


      String prompt = context + chatMessage.text;
      if (model != null) {
        // Create content for the prompt
        final content = [Content.text(prompt)];
        final response = await model!.generateContent(content);
        String responseText = response.text ?? 'Please ask a proper query!';
        
        try {
          responseText = responseText.replaceAll(RegExp(r'```json|```|\njson'), '').trim();
          responseText = responseText.replaceAll('undefined', 'null');
          print(responseText);
          Map<String, dynamic> eventData = jsonDecode(responseText);

          // print(eventData);
          String userIntent = eventData['User_Intent'] ?? 'null';
          String eventDate = eventData['Date'] ?? 'null';
          String startTimeStr = eventData['Start_Time'] ?? 'null';
          String endTimeStr = eventData['End_Time'] ?? 'null';
          String eventName = eventData['Event_name'] ?? 'null';

          if(eventName == 'null'){
            eventName = 'No_Title';
          }

          print("User Intent: $userIntent");
          print("Event Date: $eventDate");
          print("Event Start Time: $startTimeStr");
          print("Event End Time: $endTimeStr");
          print("Event Name: $eventName");

          // Parse date and time into DateTime objects
          DateTime startDate = DateTime.parse(eventDate);
          DateTime startTime = DateTime.parse("$eventDate $startTimeStr");
          DateTime endTime = endTimeStr != 'null'
              ? DateTime.parse("$eventDate $endTimeStr")
              : startTime.add(Duration(hours: 1)); // Set default 1-hour duration if end time is not provided.

          String preMessage = "";


          try {
            if (userIntent == "Add_Event") {
              await googleCalendarService.addEvent(eventName, startDate, startTime, endTime);
              preMessage = "Event added successfully on your Calendar \n";
            }
          } catch (e) {
            print("Failed to add Event to calendar: $e");
          }
          
          try {
            if (userIntent == "Shift_Event") {
              await googleCalendarService.shiftEvent(eventName, startDate, startTime, endTime);
              preMessage = "Event shifted successfully on your Calendar \n";
            }
          } catch (e) {
            print("Failed to shift Event to calendar: $e");
          }


          ChatMessage newMessage = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: "Details:- \n $preMessage Date: $eventDate, Start Time: $startTime, End Time: $endTime, Event: $eventName",
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