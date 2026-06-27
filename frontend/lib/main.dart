import 'package:flutter/material.dart';
import 'home_page.dart'; // Import the HomePage
import 'inbox.dart';
import 'settings.dart';
import 'StarredEmailPage.dart';
import 'Sample.dart';
import 'All_Mail.dart';
import 'TrashScreen.dart';
import 'SentEmailsScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: "web/.env");
  // Load the .env file
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Retrieve email from the .env file
    final String email = dotenv.env['EMAIL'] ?? 'pranalipatil572004@gmail.cpm';

    return MaterialApp(
      title: 'Flutter Email App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Disable debug banner
      initialRoute: '/',
      routes: {
        '/': (context) => EmailHomePage(email: email), // Pass email to HomePage
        '/inbox': (context) => const InboxScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/Sample': (context) => const SimpleEmailScreen(),
        '/StarredEmailPage': (context) => const StarredEmailApp(),
        '/All_Mail': (context) => const AllMailScreen(),
        '/TrashScreen': (context) => const TrashBinScreen(),
        '/SentEmailsScreen': (context) => const SentEmailsScreen(),
      },
    );
  }
}
