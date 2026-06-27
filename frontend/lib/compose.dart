import 'package:flutter/material.dart';

class ComposeEmailScreen extends StatelessWidget {
  const ComposeEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compose Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            const TextField(
              decoration: InputDecoration(labelText: 'To'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Subject'),
            ),
            const TextField(
              decoration: InputDecoration(labelText: 'Body'),
              maxLines: 8,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Add send email logic
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
