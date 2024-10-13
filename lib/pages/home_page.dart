import 'package:calendar_gemini/constants.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

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
      String context = """Suppose you are a Google Calendar Integration app and you have 
                            to help me in classifying the intent of the user with his query 
                            and just return the following neccesary data from the user's query
                            and also don't ask back any questions just return data or say that 
                            you didn't understood the query.Also if any of the field values are 
                            null then make that value as undefined. Here is the list of Event_Intents 
                            from which you have to classify don't return any User_Intent beside this:-
                            { Add_Event, Shift_Event, Cancel_Event, Add_Recurring_Event, AllDay_Event, 
                            Add_Notification}. Also sometimes you maybe asked to learn the type of User_Intent
                            if you give misclassify that User_intent then learn from the user guidance. 
                            Return the data in this JSON format:- 
                            User_Intent, Date, Time, Event_name and following is the user query:- """;
      String prompt = context + chatMessage.text;
      if (model != null) {
        // Create content for the prompt
        final content = [Content.text(prompt)];
        final response = await model!.generateContent(content);
        // print(response.text);
        String responseText = response.text ?? 'Please ask a proper query!';

        ChatMessage? lastMessage = messages.firstOrNull;
        if(lastMessage != null && lastMessage.user == geminiUser){
          lastMessage = messages.removeAt(0);
          lastMessage.text += responseText;
          setState(() {
            messages = [lastMessage!, ...messages];
          });
        } else {
          ChatMessage newMessage = ChatMessage(
            user: geminiUser,
            createdAt: DateTime.now(),
            text: responseText,
          );
          setState(() {
            messages = [newMessage, ...messages];
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }
}