// lib/screen/studentscreens/studentHome.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quizapp/screen/studentscreens/test.dart';
import 'package:quizapp/screen/studentscreens/takenTests.dart';
import 'package:quizapp/services/flutter_secure_storage.dart';

void main() => runApp(const MyApp());

/// Root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mercantec Quiz',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const StudentHome(),
      routes: {
        '/takenTests': (context) => const TakenTests(),
      },
    );
  }
}

/// Stateful widget representing the Student Home screen.
class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  _StudentHomeState createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  List<Map<String, dynamic>> lockedQuiz = [];
  final SecureStorageService _secureStorage = SecureStorageService();

  bool isLoading = true; // Tracks if data is being fetched
  String? errorMessage; // Holds error messages, if any

  /// Fetches quizzes from the API.
  Future<void> fetchQuizzes() async {
    setState(() {
      isLoading = true;
      errorMessage = null; // Reset error message before fetching
    });

    try {
      final token = await _secureStorage.readToken();
      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      final userid = await _secureStorage.readUserID();
      if (userid == null) {
        throw Exception("User ID not found. Please log in again.");
      }

      final response = await http.get(
        Uri.parse(
            'https://mercantec-quiz.onrender.com/api/User_Quiz/AllUserQuiz/$userid'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        // Ensure the response is a list
        if (jsonResponse is List) {
          DateTime now = DateTime.now();

          // Filter quizzes where 'completed' is false and 'quizEndDate' is in the future
          List<Map<String, dynamic>> filteredQuizzes =
              List<Map<String, dynamic>>.from(
            jsonResponse
                .where((quiz) =>
                    quiz['completed'] == false &&
                    DateTime.parse(quiz['quizEndDate']).isAfter(now))
                .map((quiz) => {
                      'id': quiz['quiz']['id'],
                      'title': quiz['quiz']['title'],
                    }),
          );

          setState(() {
            lockedQuiz = filteredQuizzes;
            isLoading = false;
          });
        } else {
          throw Exception("Unexpected response format.");
        }
      } else {
        throw Exception('Failed to fetch quizzes: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
      print('An error occurred: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchQuizzes(); // Fetch quizzes when the widget initializes
  }

  /// Logs out the user by deleting stored credentials and navigating to the login screen.
  Future<void> _logout() async {
    //confirmation dialog before logging out
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        // Delete the JWT token and User ID from secure storage
        await _secureStorage.deleteToken();
        await _secureStorage.deleteUserID();

        // Navigate to the login screen and remove all previous routes
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/main', (route) => false);
      } catch (e) {
        // Handle any errors during logout
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during logout: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mercantec Quiz'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // "Taken Quiz" Button
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TakenTests(),
                  ),
                );
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
            const SizedBox(height: 10),

            // "Quizzes" Heading
            const Text(
              'Quizzes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 20),

            //section for quizzes list or loading indicator/error message
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(), // Loading indicator
                    )
                  : errorMessage != null
                      ? Center(
                          child: Text(
                            errorMessage!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : lockedQuiz.isEmpty
                          ? const Center(
                              child: Text(
                                'No quizzes available.',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.builder(
                              itemCount: lockedQuiz.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ListTile(
                                    title: Text(lockedQuiz[index]['title']),
                                    onTap: () {
                                      final quizID = lockedQuiz[index]['id'];
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              Test(quizID: quizID),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
