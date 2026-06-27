import 'package:flutter/material.dart';

class EmailDetailScreen extends StatelessWidget {
  final String email;

  const EmailDetailScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Detail'),
      ),
      body: Center(
        child: Text('Detail of $email'),
      ),
    );
  }
}
