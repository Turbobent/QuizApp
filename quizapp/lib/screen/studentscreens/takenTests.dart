import 'package:flutter/material.dart';

// New screen to show the list of taken tests or relevant information
class TakenTests extends StatelessWidget {
  const TakenTests({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taken Tests'),
      ),
      body: const Center(
        child: Text(
          'List of taken tests will be displayed here.',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
