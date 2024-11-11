import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quizapp/screen/studentscreens/test.dart';
import 'package:quizapp/screen/studentscreens/takenTests.dart';
import 'package:quizapp/services/flutter_secure_storage.dart';

void main() => runApp(const StudentHome());

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  _StudentHomeState createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  List<String> lockedQuiz = [];
  List<String> openQuiz = ['Rust', 'Loops', 'Array', 'Loops'];
  List<String> takenTest = ['HTML Basics', 'C# Fundamentals'];

  final SecureStorageService _secureStorage = SecureStorageService();

  Future<void> fetchQuizzes() async {
    try {
      // Retrieve the token from secure storage
      final token = await _secureStorage.readToken();

      // Ensure that the token exists
      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      final response = await http.get(
        Uri.parse('https://mercantec-quiz.onrender.com/api/quizs'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization':
              'Bearer $token', // Include the token in the Authorization header
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        print('Quizzes fetched successfully: $jsonResponse');

        List<String> quizzes =
            List<String>.from(jsonResponse.map((quiz) => quiz['title']));

        setState(() {
          lockedQuiz = quizzes;
        });
      } else {
        print('Failed to fetch quizzes: ${response.statusCode}');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text("Failed to fetch quizzes"),
              content: Text('Error: ${response.body}'),
              actions: <Widget>[
                TextButton(
                  child: const Text("OK"),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      print('An error occurred: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text('An error occurred. Please try again.'),
            actions: <Widget>[
              TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchQuizzes();
  }

  @override
  Widget build(BuildContext context) {
    const String title = 'Mercantec Quiz';

    return MaterialApp(
      title: title,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(title),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              InkWell(
                onTap: () {
                  // Navigate to the Taken Quiz screen
                  Navigator.of(context).pushNamed('/takenTests');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Center(
                    child: Text(
                      'Taken Quiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Open Quiz',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: openQuiz.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(openQuiz[index]),
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
                'Locked Quiz',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 20),
              // Displaying fetched locked quizzes
              Expanded(
                child: ListView.builder(
                  itemCount: lockedQuiz.length,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        title: Text(lockedQuiz[
                            index]), // Displaying the quizzes from API
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
        '/takenTests': (context) => const TakenTests(),
      },
    );
  }
}
