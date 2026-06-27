// import 'package:flutter/material.dart';
// //import 'package:speech_to_text' as stt;
// import 'package:flutter_tts/flutter_tts.dart';

// class VoiceCommandScreen extends StatefulWidget {
//   @override
//   _VoiceCommandScreenState createState() => _VoiceCommandScreenState();
// }

// class _VoiceCommandScreenState extends State<VoiceCommandScreen> {
//   late stt.SpeechToText _speech;
//   bool _isListening = false;
//   String _command = '';
//   final FlutterTts _flutterTts = FlutterTts();

//   @override
//   void initState() {
//     super.initState();
//     _speech = stt.SpeechToText();
//   }

//   Future<void> _speak(String text) async {
//     await _flutterTts.speak(text);
//   }

//   void _startListening() async {
//     bool available = await _speech.initialize();
//     if (available) {
//       setState(() => _isListening = true);
//       _speech.listen(onResult: (val) => setState(() {
//         _command = val.recognizedWords.toLowerCase();
//         _isListening = false;
//         _handleVoiceCommand(_command);
//       }));
//     }
//   }

//   // New method: Ask user which inbox to open
//   void askUserForInbox() async {
//     await _speak('Which user\'s inbox would you like to open?');
//     _startListeningForInbox();
//   }

//   void _startListeningForInbox() async {
//     bool available = await _speech.initialize();
//     if (available) {
//       setState(() => _isListening = true);
//       _speech.listen(onResult: (val) => setState(() {
//         _command = val.recognizedWords.toLowerCase();
//         _isListening = false;
//         _openUserInbox(_command);
//       }));
//     }
//   }

//   void _openUserInbox(String username) {
//     _speak('Opening inbox for $username');
//     // Navigate to inbox or show emails for that username
//   }

//   void _handleVoiceCommand(String command) {
//     if (command.contains('inbox')) {
//       askUserForInbox();  // Ask for user's inbox choice
//     } else if (command.contains('sent')) {
//       _speak('Opening sent emails');
//       Navigator.pushNamed(context, '/sent');
//     } else if (command.contains('settings')) {
//       _speak('Opening settings');
//       Navigator.pushNamed(context, '/settings');
//     } else if (command.contains('trash')) {
//       _speak('Opening trash bin');
//       Navigator.pushNamed(context, '/trash');
//     } else {
//       _speak('Sorry, I didn\'t catch that. Please try again.');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Voice Command Example'),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(_isListening ? 'Listening...' : 'Tap to speak'),
//             ElevatedButton(
//               onPressed: _startListening,
//               child: Text('Start Listening'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
