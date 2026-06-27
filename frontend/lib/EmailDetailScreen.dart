// import 'package:flutter/material.dart';

// class EmailDetailScreen extends StatelessWidget {
//   final Map<String, dynamic> email;

//   const EmailDetailScreen({super.key, required this.email});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(email['subject'] ?? 'Email Detail'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'From: ${email['sender'] ?? 'Unknown'}',
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 8),
//             Text('Subject: ${email['subject'] ?? 'No Subject'}'),
//             const SizedBox(height: 16),
//             Text(email['body'] ?? 'No Content'),
//           ],
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';

class EmailDetailScreen extends StatelessWidget {
  final Map<String, dynamic> email;

  const EmailDetailScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(email['subject'] ?? 'Email Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('From: ${email['sender'] ?? 'Unknown'}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Text('Received: ${email['receivedDate'] ?? 'Unknown Date'}', style: const TextStyle(fontSize: 16)),
            const Divider(),
            Text(email['body'] ?? 'No Content', style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
