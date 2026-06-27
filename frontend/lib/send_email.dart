import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'dart:convert';

class ComposeEmailScreen extends StatefulWidget {
  const ComposeEmailScreen({super.key});

  @override
  _ComposeEmailScreenState createState() => _ComposeEmailScreenState();
}

class _ComposeEmailScreenState extends State<ComposeEmailScreen> {
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _command = '';
  String _activeField = ''; // Track which field to update based on the command

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  Future<void> _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) {
        setState(() {
          _command = val.recognizedWords.toLowerCase();
          _handleVoiceCommand(_command);
        });
      });
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  void _handleVoiceCommand(String command) {
    // Set the active field based on the command
    if (command.contains('set to')) {
      _activeField = 'to';
    } else if (command.contains('set subject')) {
      _activeField = 'subject';
    } else if (command.contains('set body')) {
      _activeField = 'body';
    } else if (command.contains('send email')) {
      _sendEmail();
    } else if (command.contains("homepage")) {
      print("Voice command recognized: Navigating to home page");
      Navigator.pushReplacementNamed(
          context, '/home_Page'); // Navigate to home page
    } else if (command.contains("inbox page")) {
      print("Voice command recognized: Navigating to inbox page");
      Navigator.pushReplacementNamed(
          context, '/InboxScreen'); // Navigate to inbox page
    } else if (command.contains("my emails")) {
      print("Voice command recognized: Navigating to sent page");
      Navigator.pushReplacementNamed(
          context, '/SentEmailsScreen'); // Navigate to sent emails page
    } else if (command.contains("all emails")) {
      print("Voice command recognized: Navigating to all emails page");
      Navigator.pushReplacementNamed(
          context, '/All_Mail'); // Navigate to all emails page
    } else if (command.contains("setting page")) {
      print("Voice command recognized: Navigating to settings page");
      Navigator.pushReplacementNamed(
          context, '/settings'); // Navigate to settings page
    } else if (command.contains("trash page")) {
      print("Voice command recognized: Navigating to trash page");
      Navigator.pushReplacementNamed(
          context, '/TrashScreen'); // Navigate to trash page
    } else if (command.contains("star page")) {
      print("Voice command recognized: Navigating to star page");
      Navigator.pushReplacementNamed(
          context, '/StarredEmailPage'); // Navigate to starred emails page
    } else {
      // If an active field is set, update it with the recognized words
      _updateActiveField(command);
    }
  }

  void _updateActiveField(String text) {
    switch (_activeField) {
      case 'to':
        _toController.text = text;
        break;
      case 'subject':
        _subjectController.text = text;
        break;
      case 'body':
        _bodyController.text = text;
        break;
      default:
        break;
    }
  }

  Future<void> _sendEmail() async {
    final to = _toController.text;
    final subject = _subjectController.text;
    final body = _bodyController.text;

    if (to.isNotEmpty && subject.isNotEmpty && body.isNotEmpty) {
      final url = Uri.parse('http://localhost:3002/send-email');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'to': to,
          'subject': subject,
          'text': body,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Email has been sent!'),
        ));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to send email'),
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please fill all fields'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Email'),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _toController,
              decoration: const InputDecoration(labelText: 'To'),
            ),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Body'),
              maxLines: 8,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendEmail,
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
