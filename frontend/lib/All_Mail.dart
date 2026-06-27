import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class AllMailScreen extends StatefulWidget {
  const AllMailScreen({super.key});

  @override
  _AllMailScreenState createState() => _AllMailScreenState();
}

class _AllMailScreenState extends State<AllMailScreen> {
  List<Map<String, dynamic>> emails = [];
  List<Map<String, dynamic>> filteredEmails = [];
  bool isLoading = true;

  late stt.SpeechToText _speech;
  late FlutterTts _tts;

  String _searchQuery = "";
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    fetchEmails();
  }

  Future<void> fetchEmails() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://localhost:3002/all-mails?email=pranalipatil572004@gmail.com'),
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);

        setState(() {
          emails = jsonResponse.map<Map<String, dynamic>>((email) {
            return {
              'type': email['type'],
              'contact':
                  email['contact'].toLowerCase().trim(), // Normalize contact
              'subject': email['subject'],
              'body': email['body'],
              'date': DateTime.parse(email['timestamp']),
            };
          }).toList();
          filteredEmails = List.from(emails); // Initially show all emails
          isLoading = false;
        });

        await _askSenderQuery();
      } else {
        throw Exception('Failed to load emails');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching emails: $e');
    }
  }

  Future<void> _askSenderQuery() async {
    await _tts.speak(
        "Do you want to search for emails from a specific sender? If yes, please say the sender's name.");
    _startListeningForSender();
  }

  void _startListeningForSender() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (available) {
      setState(() => isListening = true);
      _speech.listen(onResult: (result) {
        setState(() {
          _searchQuery = result.recognizedWords.toLowerCase().trim();
        });
        _stopListening();
        _filterEmailsBySender();
      });
    } else {
      print('Speech recognition not available');
    }
  }

  void _stopListening() {
    setState(() => isListening = false);
    _speech.stop();
  }

  void _filterEmailsBySender() async {
    if (_searchQuery.isEmpty) {
      setState(() => filteredEmails = List.from(emails));
      await _tts.speak("No query provided. Showing all emails.");
    } else {
      setState(() {
        filteredEmails = emails.where((email) {
          // Match the contact exactly or closely
          final contact = email['contact'];
          return contact.contains(_searchQuery);
        }).toList();
      });

      if (filteredEmails.isEmpty) {
        await _tts.speak("No emails found from or to $_searchQuery.");
      } else {
        await _tts.speak(
            "I found ${filteredEmails.length} emails from or to $_searchQuery. Let me read the subjects for you.");
        _askSubjectForDetails();
      }
    }
  }

  Future<void> _askSubjectForDetails() async {
    if (filteredEmails.isNotEmpty) {
      String subjects =
          filteredEmails.map((email) => email['subject']).join(', ');
      await _tts.speak(
          "Which email would you like to hear in detail? The subjects are: $subjects.");
      _startListeningForSubject();
    }
  }

  void _startListeningForSubject() async {
    bool available = await _speech.initialize(
      onStatus: (status) => print('Speech status: $status'),
      onError: (error) => print('Speech error: $error'),
    );

    if (available) {
      setState(() => isListening = true);
      _speech.listen(onResult: (result) {
        String subjectQuery = result.recognizedWords.trim().toLowerCase();
        _stopListening();
        _showEmailDetailsBySubject(subjectQuery);
      });
    } else {
      print('Speech recognition not available');
    }
  }

  void _showEmailDetailsBySubject(String subjectQuery) async {
    if (subjectQuery.isEmpty) {
      await _tts.speak("No subject provided. Please try again.");
      return;
    }

    var selectedEmail = filteredEmails.firstWhere(
      (email) => email['subject'].toLowerCase().contains(subjectQuery),
      orElse: () =>
          {'subject': '', 'body': '', 'contact': '', 'date': DateTime.now()},
    );

    if (selectedEmail['subject']!.isEmpty) {
      await _tts.speak("No emails found with the subject: $subjectQuery.");
    } else {
      await _tts
          .speak("Opening email with subject: ${selectedEmail['subject']}.");
      _showEmailDetailsDialog(selectedEmail);
    }
  }

  void _showEmailDetailsDialog(Map<String, dynamic> email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(email['subject'] ?? 'No Subject'),
        content: Text(email['body'] ?? 'No Content'),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Mail'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : filteredEmails.isEmpty
                ? const Center(child: Text('No emails found'))
                : ListView.builder(
                    itemCount: filteredEmails.length,
                    itemBuilder: (context, index) {
                      final email = filteredEmails[index];
                      return ListTile(
                        leading: Icon(
                            email['type'] == 'sent' ? Icons.send : Icons.inbox),
                        title: Text(
                          email['subject'] ?? 'No Subject',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          email['type'] == 'sent'
                              ? 'To: ${email['contact']}'
                              : 'From: ${email['contact']}',
                        ),
                        trailing: Text(
                          DateFormat('yyyy-MM-dd').format(email['date']),
                          style: const TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          _showEmailDetailsDialog(email);
                        },
                      );
                    },
                  ),
      ),
    );
  }
}
