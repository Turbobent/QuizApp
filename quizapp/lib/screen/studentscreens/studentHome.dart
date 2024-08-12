import 'package:flutter/material.dart';
import 'package:quizapp/screen/studentscreens/test.dart';

void main() => runApp(const StudentHome());

class StudentHome extends StatelessWidget {
  const StudentHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const String _title = 'Mercantec Quiz';

    // List of test names
    List<String> upcomingTest = [
      'HTML 10-9 10:30',
      'C# 23-1 8:23',
      'Flutter 12-4 18:00',
      'PC parts 29-8 13:00',
      'Test 5',
    ];

    List<String> availableTest = [
      'Rust 10-9 10:30',
      'Loops 23-1 8:23',
      'Array 23-1 11:30',
      'Loops 23-1 8:23',
    ];

    return MaterialApp(
      title: _title,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(_title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(availableTest[index]),
                        onTap: () {
                          Navigator.of(context).pushNamed('/test');
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
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: upcomingTest.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(upcomingTest[index]),
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
      routes: {
        '/test': (context) => const Test(),
      },
    );
  }
}
