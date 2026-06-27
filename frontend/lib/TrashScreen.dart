import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TrashBinScreen extends StatefulWidget {
  const TrashBinScreen({super.key});

  @override
  _TrashBinScreenState createState() => _TrashBinScreenState();
}

class _TrashBinScreenState extends State<TrashBinScreen> {
  final List<Map<String, dynamic>> emails = [
    {
      'from': 'user1@gmail.com',
      'to': 'user@example.com',
      'subject': 'Old News',
      'body': 'This is an old email...',
      'date': DateTime.now().subtract(const Duration(days: 30)),
      'isUnread': true
    },
    {
      'from': 'user2@gmail.com',
      'to': 'user@example.com',
      'subject': 'Important Notice',
      'body': 'Please read this...',
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'isUnread': false
    },
    // Add more emails here
  ];

  DateTime? selectedDate;
  String? selectedSender;
  bool showUnreadOnly = false;

  void restoreEmail(int index) {
    setState(() {
      emails.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email restored to inbox')),
    );
  }

  void deleteEmail(int index) {
    setState(() {
      emails.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email permanently deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredEmails = emails.where((email) {
      bool matchesDate = selectedDate == null || DateFormat('yyyy-MM-dd').format(email['date']) == DateFormat('yyyy-MM-dd').format(selectedDate!);
      bool matchesSender = selectedSender == null || email['from'] == selectedSender;
      bool matchesUnread = !showUnreadOnly || email['isUnread'] == true;

      return matchesDate && matchesSender && matchesUnread;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trash'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Select Date (YYYY-MM-DD)'),
              onChanged: (value) {
                setState(() {
                  selectedDate = value.isNotEmpty ? DateTime.tryParse(value) : null;
                });
              },
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'From'),
              onChanged: (value) {
                setState(() {
                  selectedSender = value.isNotEmpty ? value : null;
                });
              },
            ),
            Row(
              children: [
                const Text('Show Unread Only'),
                Checkbox(
                  value: showUnreadOnly,
                  onChanged: (value) {
                    setState(() {
                      showUnreadOnly = value ?? false;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: filteredEmails.length,
                itemBuilder: (context, index) {
                  final email = filteredEmails[index];
                  return ListTile(
                    leading: Icon(email['isUnread'] ? Icons.mark_email_unread : Icons.email),
                    title: Text(email['subject'] ?? 'No Subject'),
                    subtitle: Text('From: ${email['from']}'),
                    trailing: Text(DateFormat('yyyy-MM-dd').format(email['date'])),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(email['subject'] ?? 'No Subject'),
                          content: Text(email['body'] ?? 'No Body'),
                          actions: [
                            TextButton(
                              child: const Text('Restore'),
                              onPressed: () {
                                restoreEmail(emails.indexOf(email));
                                Navigator.pop(context);
                              },
                            ),
                            TextButton(
                              child: const Text('Delete'),
                              onPressed: () {
                                deleteEmail(emails.indexOf(email));
                                Navigator.pop(context);
                              },
                            ),
                            TextButton(
                              child: const Text('Close'),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
