import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quizapp/services/flutter_secure_storage.dart';

// Model class for a taken test
class TakenTest {
  final String testName;
  final String dateTaken;
  final int score;
  final int totalQuestions;

  TakenTest({
    required this.testName,
    required this.dateTaken,
    required this.score,
    required this.totalQuestions,
  });

  // Factory constructor to create a TakenTest instance from JSON
  factory TakenTest.fromJson(Map<String, dynamic> json) {
    return TakenTest(
      testName: json['quiz']['title'] ?? 'Unknown Title',
      dateTaken: json['quizEndDate'] ?? 'Unknown Date',
      score: json['results'] ?? 0,
      totalQuestions: json['quiz']['qestionsAmount'] ?? 0,
    );
  }
}

class TakenTests extends StatefulWidget {
  const TakenTests({super.key});

  @override
  _TakenTestsState createState() => _TakenTestsState();
}

class _TakenTestsState extends State<TakenTests> {
  List<TakenTest> takenTests = [];
  bool isLoading = true;
  final SecureStorageService _secureStorage = SecureStorageService();

  @override
  void initState() {
    super.initState();
    _fetchTakenTests();
  }

  Future<void> _fetchTakenTests() async {
    // Retrieve the user ID from secure storage as a string
    final userIdString = await _secureStorage.readUserID();

    // Convert userIdString to an integer, defaulting to 0 if null or invalid
    final int userId = int.tryParse(userIdString ?? '0') ?? 0;

    final String url =
        'https://mercantec-quiz.onrender.com/api/User_Quiz/AllUserQuiz/$userId';

    try {
      // Retrieve the JWT token from secure storage
      final token = await _secureStorage.readToken();
      if (token == null) {
        print('Error: Token not found');
        return;
      }

      // Make the GET request with the JWT token in the headers
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        // Filter the data to include only completed tests
        final completedTests = data
            .where((item) => item['completed'] == true)
            .map((item) => TakenTest.fromJson(item))
            .toList();

        setState(() {
          takenTests = completedTests;
          isLoading = false;
        });
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Taken Tests'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: ListView.builder(
                itemCount: takenTests.length,
                itemBuilder: (context, index) {
                  final test = takenTests[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        test.testName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Text('Date Taken: ${test.dateTaken}'),
                      trailing: Text(
                        'Score: ${test.score}',
                        style: TextStyle(
                          color: test.score >= test.totalQuestions / 2
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
