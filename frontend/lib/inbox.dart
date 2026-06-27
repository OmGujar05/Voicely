import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart'; // For Text-to-Speech
import 'package:speech_to_text/speech_to_text.dart'
    as stt; // For Speech Recognition

class InboxScreen extends StatefulWidget {
  const InboxScreen({super.key});

  @override
  _InboxScreenState createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  List<Map<String, dynamic>> inboxEmails = [];
  bool isLoading = true;
  String errorMessage = '';
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speechToText;
  String recognizedWords = "";

  @override
  void initState() {
    super.initState();
    _flutterTts = FlutterTts();
    _speechToText = stt.SpeechToText();
    fetchInboxEmails(); // Fetch inbox emails
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> fetchInboxEmails() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3002/inbox-emails'));
      if (response.statusCode == 200) {
        final List<dynamic> emails = json.decode(response.body);
        setState(() {
          inboxEmails = emails
              .map((email) => {
                    'sender': email['sender'],
                    'subject': email['subject'],
                    'body': email['body'],
                    'receivedDate': email['timestamp'],
                  })
              .toList();
          isLoading = false;
        });

        // Automatically start reading the latest emails
        readLatestEmails();
      } else {
        throw Exception('Failed to load inbox emails');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load emails: $e';
        isLoading = false;
      });
    }
  }

  Future<void> readLatestEmails() async {
    if (inboxEmails.isEmpty) {
      await _flutterTts.speak("No emails are available in your inbox.");
      return;
    }

    final latestEmails = inboxEmails.take(3).toList();
    await _flutterTts.awaitSpeakCompletion(true);

    for (int i = 0; i < latestEmails.length; i++) {
      final email = latestEmails[i];
      final sender = email['sender'] ?? "Unknown sender";
      final subject = email['subject'] ?? "No subject";

      await _flutterTts
          .speak("Email number ${i + 1}. From: $sender. Subject: $subject.");
      await Future.delayed(const Duration(seconds: 2));
    }

    await _flutterTts.speak(
        "Which email would you like to hear in detail? Please say Email 1, Email 2, or Email 3.");
    listenForSelection(); // Start listening after announcing the options
  }

  void listenForSelection() async {
    String userChoice = await getVoiceInput();

    // Log the recognized words for debugging
    print("Recognized voice input: $userChoice");

    // Normalize the input by trimming extra spaces and converting to lowercase
    userChoice = userChoice.trim().toLowerCase();

    int emailIndex;
    switch (userChoice) {
      case 'email 1':
      case 'email one':
        emailIndex = 0;
        break;
      case 'email 2':
      case 'email to':
        emailIndex = 1;
        break;
      case 'email 3':
      case 'email three':
        emailIndex = 2;
        break;
      default:
        await _flutterTts.speak("Invalid choice. Please say Email 1, 2, or 3.");
        return listenForSelection();
    }

    final selectedEmail = inboxEmails[emailIndex];
    final sender = selectedEmail['sender'] ?? "Unknown sender";
    final subject = selectedEmail['subject'] ?? "No subject";
    final body = selectedEmail['body'] ?? "No content.";
    await _flutterTts
        .speak("Reading email from $sender. Subject: $subject. Body: $body.");

    // After reading, ask for reply option
    await _flutterTts
        .speak("Do you want to reply to this email? Please say yes or no.");
    handleReplyOption(selectedEmail);
  }

  Future<String> getVoiceInput() async {
    bool available = await _speechToText.initialize();
    if (available) {
      _speechToText.listen(onResult: (result) {
        setState(() {
          recognizedWords = result.recognizedWords.toLowerCase();
        });
      });

      // Wait for the user to finish speaking
      await Future.delayed(const Duration(seconds: 5));
      _speechToText.stop();

      return recognizedWords;
    } else {
      await _flutterTts.speak("Voice input is not available on your device.");
      return "";
    }
  }

  void handleReplyOption(Map<String, dynamic> selectedEmail) async {
    String userChoice = await getVoiceInput();

    if (userChoice.contains("yes")) {
      // If user says 'yes', initiate email reply
      await _flutterTts.speak("Please dictate your reply.");

      String replyText = await getVoiceInput(); // Get the reply text
      await sendReplyEmail(selectedEmail, replyText); // Send the reply
    } else if (userChoice.contains("no")) {
      await _flutterTts.speak("No reply will be sent.");
    } else {
      await _flutterTts.speak("I didn't understand. Please say yes or no.");
      handleReplyOption(selectedEmail); // Retry if the response is invalid
    }
  }

  Future<void> sendReplyEmail(
      Map<String, dynamic> selectedEmail, String replyText) async {
    if (replyText.isEmpty) {
      await _flutterTts.speak("Your reply text is empty. Please try again.");
      return;
    }

    try {
      final String recipient = selectedEmail['sender'] ?? "";
      final String originalSubject = selectedEmail['subject'] ?? "No Subject";

      if (recipient.isEmpty) {
        await _flutterTts.speak("The recipient's email address is missing.");
        return;
      }

      final Map<String, String> payload = {
        'to': recipient,
        'subject': 'Re: $originalSubject',
        'text': replyText, // Correct field name as per backend requirement
      };

      print("Sending email with payload: $payload"); // Debugging

      final response = await http.post(
        Uri.parse('http://localhost:3002/send-email'),
        headers: <String, String>{
          'Content-Type': 'application/json',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        await _flutterTts.speak("Your reply has been sent successfully.");
      } else {
        print("Error response status: ${response.statusCode}");
        print("Error response body: ${response.body}");
        await _flutterTts.speak(
            "Failed to send the reply. The server responded with an error.");
      }
    } catch (e) {
      print("Exception while sending email: $e");
      await _flutterTts.speak(
          "An error occurred while sending the reply. Please check your connection and try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : inboxEmails.isEmpty
                  ? const Center(child: Text('No emails found'))
                  : ListView.builder(
                      itemCount: inboxEmails.length,
                      itemBuilder: (context, index) {
                        final email = inboxEmails[index];
                        return ListTile(
                          title: Text('From: ${email['sender'] ?? 'Unknown'}'),
                          subtitle: Text(
                              'Subject: ${email['subject'] ?? 'No Subject'}'),
                          onTap: () async {
                            final body = email['body'] ?? "No content.";
                            await _flutterTts.speak("Reading email. $body.");
                          },
                        );
                      },
                    ),
    );
  }
}
