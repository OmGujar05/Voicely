import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_tts/flutter_tts.dart';

class SentEmailsScreen extends StatefulWidget {
  const SentEmailsScreen({super.key});

  @override
  _SentEmailsScreenState createState() => _SentEmailsScreenState();
}

class _SentEmailsScreenState extends State<SentEmailsScreen> {
  DateTime? selectedDate;
  String? selectedRecipient;
  List<Map<String, dynamic>> sentEmails = [];
  final FlutterTts flutterTts = FlutterTts(); // Initialize TTS instance

  @override
  void initState() {
    super.initState();
    fetchSentEmails();
  }

  // Fetch sent emails from the backend
  Future<void> fetchSentEmails() async {
    try {
      final response =
          await http.get(Uri.parse('http://localhost:3002/sent-emails'));
      if (response.statusCode == 200) {
        final List<dynamic> emails = json.decode(response.body);
        setState(() {
          sentEmails = emails.map((email) {
            return {
              "to": email["recipient"],
              "subject": email["subject"],
              "preview": email["body"],
              "date": DateTime.parse(email["timestamp"]),
              "isUnread": false, // Adjust this based on your data if needed
            };
          }).toList();
        });
        _readLatestEmail(); // Read the latest email after fetching
      } else {
        print(
            'Failed to load sent emails. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching sent emails: $e');
    }
  }

  // Function to read the latest email
  Future<void> _readLatestEmail() async {
    if (sentEmails.isNotEmpty) {
      final latestEmail = sentEmails[0]; // Latest email from the list
      final message = "The latest email was sent to ${latestEmail['to']} "
          "with the subject ${latestEmail['subject']}. "
          "The message is: ${latestEmail['preview']}.";
      await flutterTts.speak(message); // Speak the message
    } else {
      await flutterTts.speak("There are no sent emails to display.");
    }
  }

  @override
  void dispose() {
    flutterTts.stop(); // Stop any ongoing TTS when the screen is closed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<String> recipients =
        sentEmails.map((e) => e['to'].toString()).toSet().toList();

    List<Map<String, dynamic>> filteredEmails = sentEmails.where((email) {
      final matchesRecipient =
          selectedRecipient == null || email['to'] == selectedRecipient;
      final matchesDate = selectedDate == null ||
          DateFormat('yyyy-MM-dd').format(email['date']) ==
              DateFormat('yyyy-MM-dd').format(selectedDate!);
      return matchesRecipient && matchesDate;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sent Emails'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null && picked != selectedDate) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(selectedDate == null
                      ? 'Select Date'
                      : DateFormat('yyyy-MM-dd').format(selectedDate!)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: const Text("Select Recipient"),
                    value: selectedRecipient,
                    items: recipients.map((String recipient) {
                      return DropdownMenuItem<String>(
                        value: recipient,
                        child: Text(recipient),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedRecipient = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredEmails.length,
              itemBuilder: (context, index) {
                final email = filteredEmails[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(email['to'][0].toUpperCase()),
                  ),
                  title: Text(
                    email['to'],
                    style: TextStyle(
                      fontWeight: email['isUnread']
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email['subject'],
                        style: TextStyle(
                          fontWeight: email['isUnread']
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        email['preview'],
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  trailing: Text(
                    DateFormat('hh:mm a').format(email['date']),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  onTap: () {
                    print('Opening email: ${email['subject']}');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: SentEmailsScreen(),
  ));
}
