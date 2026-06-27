
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart'; // For text-to-speech functionality

class EmailHomePage extends StatefulWidget {
  final String email;

  const EmailHomePage({super.key, required this.email});

  @override
  _EmailHomePageState createState() => _EmailHomePageState();
}

class _EmailHomePageState extends State<EmailHomePage> {
  late stt.SpeechToText _speech;
  late FlutterTts _tts; // Text-to-speech instance
  bool _isListening = false;
  bool _isSpeaking = false;
  String _command = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts(); // Initialize text-to-speech
    _startListening(); // Automatically start listening
  }

  void _startListening() async {
    bool available = await _speech.initialize(
      onStatus: (val) => print('onStatus: $val'),
      onError: (val) => print('onError: $val'),
    );
    if (available) {
      setState(() => _isListening = true);
      _speech.listen(onResult: (val) => setState(() {
            _command = val.recognizedWords.toLowerCase();
            _handleVoiceCommand(_command);
          }));
    }
  }

  void _stopListening() {
    setState(() => _isListening = false);
    _speech.stop();
  }

  void _handleVoiceCommand(String command) async {
    if (command.contains('compose')) {
      await _speak("Navigating to Compose");
      Navigator.pushNamed(context, '/Sample');
    } else if (command.contains('inbox')) {
      await _speak("Opening Inbox");
      Navigator.pushNamed(context, '/inbox');
    } else if (command.contains('star')) {
      await _speak("Opening Starred Emails");
      Navigator.pushNamed(context, '/StarredEmailPage');
    } else if (command.contains('trash')) {
      await _speak("Opening Trash");
      Navigator.pushNamed(context, '/TrashScreen');
    } else if (command.contains('settings')) {
      await _speak("Opening Settings");
      Navigator.pushNamed(context, '/settings');
    } else if (command.contains('all email')) {
      await _speak("Showing All Emails");
      Navigator.pushNamed(context, '/All_Mail');
    } else if (command.contains('my emails')) {
      await _speak("Showing Sent Emails");
      Navigator.pushNamed(context, '/SentEmailsScreen');
    } else {
      // await _speak("Command not recognized");
    }
  }

  // Function to speak feedback messages
  Future<void> _speak(String message) async {
    setState(() => _isSpeaking = true);
    await _tts.speak(message);
    setState(() => _isSpeaking = false);
  }

  // Function to display email address in a dialog
  void _showEmailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Your Email Address'),
          content: Text(widget.email),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the first part of the email before '@' to get the initial
    String emailInitial = widget.email.split('@')[0].isNotEmpty
        ? widget.email.split('@')[0][0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/vemail.png',
          height: 60,
        ),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
            onPressed: _isListening ? _stopListening : _startListening,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: _showEmailDialog, // Show email dialog on tap
              child: CircleAvatar(
                backgroundColor: const Color(0xFF874F9F),
                child: Text(
                  emailInitial, // Display initial letter of the email's username
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Opacity(
              opacity: 0.05,
              child: Image.asset(
                'assets/vemail.png',
                fit: BoxFit.cover,
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.inbox),
                title: const Text('Inbox'),
                onTap: () {
                  Navigator.pushNamed(context, '/inbox');
                },
              ),
              ListTile(
                leading: const Icon(Icons.star),
                title: const Text('Starred'),
                onTap: () {
                  Navigator.pushNamed(context, '/StarredEmailPage');
                },
              ),
              ListTile(
                leading: const Icon(Icons.send),
                title: const Text('Sent'),
                onTap: () {
                  Navigator.pushNamed(context, '/SentEmailsScreen');
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Trash'),
                onTap: () {
                  Navigator.pushNamed(context, '/TrashScreen');
                },
              ),
              ListTile(
                leading: const Icon(Icons.mail),
                title: const Text('All Mail'),
                onTap: () {
                  Navigator.pushNamed(context, '/All_Mail');
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
              ),
            ],
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/Sample');
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.create, color: Color(0xFF874F9F)),
                  SizedBox(width: 8), // Space between icon and text
                  Text(
                    'Compose',
                    style: TextStyle(color: Color(0xFF874F9F)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
