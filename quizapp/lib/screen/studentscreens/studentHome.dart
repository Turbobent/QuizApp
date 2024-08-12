import 'package:flutter/material.dart';

void main() => runApp(const StudentHome());

// Use proper class naming conventions (PascalCase)
class StudentHome extends StatelessWidget {
  const StudentHome({super.key});

  @override
  Widget build(BuildContext context) {
    // List of test names
    List<String> upcommingTest = [
      'HTML 10-9 10:30',
      'C# 23-1 8:23',
      'Flutter 12-4 18:00',
      'PC parts 29-8 13:00',
      'Test 5',
    ];
      List<String> availableTest = [
      'rust 10-9 10:30',
      'loops 23-1 8:23',
    ];

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Mercantec Quiz'),
        ),
        body: Padding(  // Add padding for better layout
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start (left)
            children: <Widget>[
              const SizedBox(height: 20),
              const Text(
                'Available Tests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
               Expanded(
                child: ListView.builder(
                  itemCount: availableTest.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(  // Use Card for better visual separation
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(availableTest[index]),
                        onTap: () {
                          // Handle tap on the test name if needed
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Upcoming Tests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 20), // Space between the header and the list
              Expanded(
                child: ListView.builder(
                  itemCount: upcommingTest.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(  // Use Card for better visual separation
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(upcommingTest[index]),
                        onTap: () {
                          // Handle tap on the test name if needed
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
