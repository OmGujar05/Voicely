import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:convert';

class SimpleEmailScreen extends StatefulWidget {
  const SimpleEmailScreen({super.key});

  @override
  _SimpleEmailScreenState createState() => _SimpleEmailScreenState();
}

class _SimpleEmailScreenState extends State<SimpleEmailScreen> {
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  final FocusNode _toFocusNode = FocusNode();
  final FocusNode _subjectFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();

  late stt.SpeechToText _speech;
  late FlutterTts _flutterTts;
  bool _isListening = false;
  TextEditingController? _activeController;
  FocusNode? _activeFocusNode;
  bool _hasSentEmail = false; // To prevent sending email more than once
  bool _isSendingEmail = false; // To block multiple email send requests

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _flutterTts = FlutterTts();

    _configureTTS();

    _activeController = _toController;
    _activeFocusNode = _toFocusNode;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  void _configureTTS() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5); // Adjust for better clarity
  }

  Future<void> _sendEmail() async {
    // Prevent sending multiple times
    if (_isSendingEmail || _hasSentEmail) return;

    setState(() {
      _isSendingEmail = true; // Set the flag to block multiple calls
    });

    final to = _toController.text;
    final subject = _subjectController.text;
    String body = _bodyController.text;

    if (body.isNotEmpty) {
      List<String> bodyWords = body.split(' ');
      if (bodyWords.length > 1) {
        bodyWords.removeLast();
        body = bodyWords.join(' ');
      }
    }

    if (to.isNotEmpty && subject.isNotEmpty && body.isNotEmpty) {
      final url = Uri.parse('http://localhost:3002/send-email');

      try {
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email sent successfully!')),
          );
          await _speak('Email has been sent successfully');
          setState(() {
            _hasSentEmail = true; // Mark email as sent
          });
          _restartForm(); // Reset the form
        } else {
          final errorMsg =
              jsonDecode(response.body)['message'] ?? 'Failed to send email.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg)),
          );
          await _speak('Failed to send email');
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
        await _speak('Error sending email');
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      await _speak('Please fill in all fields');
    }

    setState(() {
      _isSendingEmail = false; // Reset the flag after email attempt
    });
  }

  Future<void> _speak(String message) async {
    try {
      await _flutterTts.speak(message);
    } catch (error) {
      print('TTS Error: $error');
    }
  }

  void _startListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(onResult: (result) {
          String recognizedWords = result.recognizedWords.toLowerCase().trim();

          if (recognizedWords.contains("send email")) {
            _sendEmail();
          } else if (recognizedWords.contains("next")) {
            _switchToNextField();
          } else if (recognizedWords.contains("subject")) {
            _setFocusToField(_subjectController, _subjectFocusNode);
          } else if (recognizedWords.contains("body")) {
            _setFocusToField(_bodyController, _bodyFocusNode);
          } else if (recognizedWords.contains("restart")) {
            _restartForm();
          } else if (recognizedWords.contains("to")) {
            _setFocusToField(_toController, _toFocusNode);
          } else if (recognizedWords.contains("homepage")) {
            print("Voice command recognized: Navigating to home page");
            Navigator.pushReplacementNamed(context, '/home_Page');
          } else if (recognizedWords.contains("inbox page")) {
            print("Voice command recognized: Navigating to inbox page");
            Navigator.pushReplacementNamed(context, '/InboxScreen');
          } else if (recognizedWords.contains("my emails")) {
            print("Voice command recognized: Navigating to sent page");
            Navigator.pushReplacementNamed(context, '/SentEmailsScreen');
          } else if (recognizedWords.contains("all emails")) {
            print("Voice command recognized: Navigating to all emails page");
            Navigator.pushReplacementNamed(context, '/All_Mail');
          } else if (recognizedWords.contains("setting page")) {
            print("Voice command recognized: Navigating to setting page");
            Navigator.pushReplacementNamed(context, '/settings');
          } else if (recognizedWords.contains("trash page")) {
            print("Voice command recognized: Navigating to trash page");
            Navigator.pushReplacementNamed(context, '/TrashScreen');
          } else if (recognizedWords.contains("star page")) {
            print("Voice command recognized: Navigating to star page");
            Navigator.pushReplacementNamed(context, '/StarredEmailPage');
          } else {
            _fillActiveField(recognizedWords);
          }
        });
      }
    }
  }

  void _stopListening() {
    if (_isListening) {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  void _fillActiveField(String command) {
    List<String> ignoredWords = [
      "send email",
      "next",
      "subject",
      "body",
      "restart",
      "to",
      "compose",
      "home page",
      "inbox page",
      "my email",
      "all emails",
      "setting page",
      "trash page",
      "star page"
    ];

    if (ignoredWords.any((ignored) => command.contains(ignored))) {
      return;
    }

    setState(() {
      if (_activeController == _toController) {
        command = command.replaceAll(" ", "");
      }
      _activeController!.text = command;
    });
  }

  void _switchToNextField() {
    setState(() {
      if (_activeController == _toController) {
        _activeController = _subjectController;
        _activeFocusNode = _subjectFocusNode;
      } else if (_activeController == _subjectController) {
        _activeController = _bodyController;
        _activeFocusNode = _bodyFocusNode;
      }
    });

    FocusScope.of(context).requestFocus(_activeFocusNode);
    _stopListening();
    Future.delayed(const Duration(milliseconds: 500), () {
      _startListening();
    });
  }

  void _setFocusToField(TextEditingController controller, FocusNode focusNode) {
    setState(() {
      _activeController = controller;
      _activeFocusNode = focusNode;
    });

    FocusScope.of(context).requestFocus(_activeFocusNode);
    _stopListening();
    Future.delayed(const Duration(milliseconds: 500), () {
      _startListening();
    });
  }

  void _restartForm() {
    setState(() {
      _toController.clear();
      _subjectController.clear();
      _bodyController.clear();

      _activeController = _toController;
      _activeFocusNode = _toFocusNode;
      _hasSentEmail = false; // Reset the flag after form restart
    });

    FocusScope.of(context).requestFocus(_activeFocusNode);
    _stopListening();
    Future.delayed(const Duration(milliseconds: 500), () {
      _startListening();
    });
  }

  @override
  void dispose() {
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Email with Voice Control'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.05,
                child: Image.asset(
                  'assets/vemail.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                TextField(
                  controller: _toController,
                  focusNode: _toFocusNode,
                  decoration: const InputDecoration(labelText: 'To'),
                ),
                TextField(
                  controller: _subjectController,
                  focusNode: _subjectFocusNode,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: _bodyController,
                  focusNode: _bodyFocusNode,
                  decoration: const InputDecoration(labelText: 'Body'),
                  maxLines: 8,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _hasSentEmail ? null : _sendEmail,
                  child: const Text('Send Email'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
