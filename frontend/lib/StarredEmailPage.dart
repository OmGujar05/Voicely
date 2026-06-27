import 'package:flutter/material.dart';

void main() {
  runApp(const StarredEmailApp());
}

class StarredEmailApp extends StatelessWidget {
  const StarredEmailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Starred Email',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StarredEmailPage(),
    );
  }
}

class StarredEmailPage extends StatefulWidget {
  const StarredEmailPage({super.key});

  @override
  _StarredEmailPageState createState() => _StarredEmailPageState();
}

class _StarredEmailPageState extends State<StarredEmailPage> {
  bool isStarred = true; // Default filter for starred emails
  DateTime? fromDate;
  DateTime? toDate;

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != fromDate) {
      setState(() {
        fromDate = picked;
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != toDate) {
      setState(() {
        toDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Starred Emails'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Is Starred:'),
                Switch(
                  value: isStarred,
                  onChanged: (value) {
                    setState(() {
                      isStarred = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Text('From: '),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _selectFromDate(context),
                  child: Text(fromDate != null
                      ? '${fromDate!.toLocal()}'.split(' ')[0]
                      : 'Anytime'),
                ),
                const SizedBox(width: 16),
                const Text('To: '),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _selectToDate(context),
                  child: Text(toDate != null
                      ? '${toDate!.toLocal()}'.split(' ')[0]
                      : 'Anytime'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            // Simulated list of starred emails
            Expanded(
              child: ListView(
                children: List.generate(10, (index) {
                  return ListTile(
                    leading: const Icon(Icons.star, color: Colors.yellow),
                    title: Text('Email $index'),
                    subtitle: Text('This is the detail of email $index.'),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
