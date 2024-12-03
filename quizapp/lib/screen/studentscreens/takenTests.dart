// lib/screen/studentscreens/takenTests.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quizapp/services/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // Imported intl for date formatting

// Model class for a taken test
class TakenTest {
  final int quizID; // Added quizID to uniquely identify each test
  final String testName;
  final String dateTaken;
  final int score;
  final int maxPoints;

  TakenTest({
    required this.quizID,
    required this.testName,
    required this.dateTaken,
    required this.score,
    required this.maxPoints,
  });

  // Factory constructor to create a TakenTest instance from JSON
  factory TakenTest.fromJson(
      Map<String, dynamic> json, int maxPoints, int quizID) {
    return TakenTest(
      quizID: quizID,
      testName: json['quiz']['title'] ?? 'Unknown Title',
      dateTaken: json['quizEndDate'] ?? 'Unknown Date',
      score: json['results'] ?? 0,
      maxPoints: maxPoints,
    );
  }

  // Getter to return formatted date
  String get formattedDate {
    try {
      DateTime parsedDate = DateTime.parse(dateTaken);
      return DateFormat('dd-MM-yyyy').format(parsedDate);
    } catch (e) {
      // If the date cannot be parsed, return the original string
      return dateTaken;
    }
  }
}

class TakenTests extends StatefulWidget {
  const TakenTests({super.key});

  @override
  _TakenTestsState createState() => _TakenTestsState();
}

class _TakenTestsState extends State<TakenTests> {
  // All taken tests fetched from the server
  List<TakenTest> allTakenTests = [];
  // Displayed taken tests after applying search filter
  List<TakenTest> displayedTakenTests = [];
  bool isLoading = true;
  final SecureStorageService _secureStorage = SecureStorageService();

  // Pagination variables
  int currentPage = 1;
  final int itemsPerPage = 5;

  // Search related variables
  final TextEditingController _searchController = TextEditingController();
  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _fetchTakenTests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Fetches the list of taken tests along with their max points
  Future<void> _fetchTakenTests() async {
    setState(() {
      isLoading = true;
      currentPage = 1; // Reset to first page on refresh
    });

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
        _showErrorDialog('Authentication Error', 'Please log in again.');
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
        final completedTests =
            data.where((item) => item['completed'] == true).toList();

        // If no completed tests, update the state accordingly
        if (completedTests.isEmpty) {
          setState(() {
            allTakenTests = [];
            displayedTakenTests = [];
            isLoading = false;
            isSearching = false;
          });
          return;
        }

        // Prepare a list of Futures to fetch quiz details and questions concurrently
        List<Future<TakenTest?>> futures = completedTests.map((test) async {
          // Correct extraction of quizID from nested 'quiz' object
          int quizID = 0;
          if (test.containsKey('quiz') &&
              test['quiz'] is Map<String, dynamic>) {
            quizID = test['quiz']['id'] != null
                ? int.parse(test['quiz']['id'].toString())
                : 0;
          }

          if (quizID == 0) {
            print('Invalid quizID for test: $test');
            return null; // Skip if quizID is invalid
          }

          // Fetch quiz details using the new endpoint
          final quizDetails = await _fetchQuizDetails(quizID, token);
          if (quizDetails == null) {
            print('Failed to fetch quiz details for quizID: $quizID');
            return null; // Skip if failed to fetch quiz details
          }

          // Fetch all questions for the quiz using the new endpoint
          final List<Map<String, dynamic>> questions =
              await _fetchQuestionsByQuizID(quizID, token);
          if (questions.isEmpty) {
            print('No questions found for quizID: $quizID');
            return null; // Skip if no questions found
          }

          // Calculate maxPoints based on quiz and question difficulties
          int maxPoints = _calculateMaxPoints(
              quizDifficulty: quizDetails['difficulty'] ?? 'h1',
              questions: questions);

          // Prevent division by zero
          if (maxPoints == 0) {
            maxPoints = 1;
          }

          // Create TakenTest instance with quizID
          TakenTest takenTest = TakenTest.fromJson(test, maxPoints, quizID);
          return takenTest;
        }).toList();

        // Execute all Futures concurrently
        List<TakenTest?> results = await Future.wait(futures);

        // Remove any nulls from the results
        List<TakenTest> fetchedTakenTests =
            results.whereType<TakenTest>().toList();

        setState(() {
          allTakenTests = fetchedTakenTests;
          // If not searching, display all taken tests
          if (!isSearching) {
            displayedTakenTests = allTakenTests;
          }
          isLoading = false;
        });
      } else {
        print('Failed to load data: ${response.statusCode}');
        _showErrorDialog('Data Fetch Error',
            'Failed to load taken tests. Please try again later.');
      }
    } catch (e) {
      print('Error fetching data: $e');
      _showErrorDialog(
          'Network Error', 'An error occurred while fetching data.');
    }
  }

  /// Fetches quiz details for a given quizID
  Future<Map<String, dynamic>?> _fetchQuizDetails(
      int quizID, String token) async {
    final String url = 'https://mercantec-quiz.onrender.com/api/Quizs/$quizID';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> quizData = jsonDecode(response.body);

        // Handle the typo in 'qestionsAmount'
        int questionsAmount = 0;
        if (quizData.containsKey('questionsAmount')) {
          questionsAmount = quizData['questionsAmount'] ?? 0;
        } else if (quizData.containsKey('qestionsAmount')) {
          // Handle typo
          questionsAmount = quizData['qestionsAmount'] ?? 0;
        }

        // Extract question IDs from the quizData using the new endpoint
        // Since we are using the new endpoint to fetch questions, we don't need to extract question IDs here

        return {
          'difficulty': quizData['difficulty'] ?? 'h1',
          // 'questionIDs': questionIDs, // Not needed with the new endpoint
        };
      } else {
        print(
            'Failed to fetch quiz details for quizID: $quizID, Status Code: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching quiz details for quizID: $quizID, Error: $e');
      return null;
    }
  }

  /// Fetches all question details for a given quizID using the new endpoint
  Future<List<Map<String, dynamic>>> _fetchQuestionsByQuizID(
      int quizID, String token) async {
    List<Map<String, dynamic>> fetchedQuestions = [];
    final String url =
        'https://mercantec-quiz.onrender.com/api/Questions/ByQuizID/$quizID';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> questionsData = jsonDecode(response.body);
        // Ensure that the response is a list
        if (questionsData is List) {
          for (var question in questionsData) {
            if (question is Map<String, dynamic>) {
              fetchedQuestions.add(question);
            }
          }
        } else {
          print('Unexpected data format for questions by quizID: $quizID');
        }
      } else {
        print(
            'Failed to fetch questions for quizID: $quizID, Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching questions for quizID: $quizID, Error: $e');
    }

    return fetchedQuestions;
  }

  /// Calculates the maximum possible points based on quiz and question difficulties
  int _calculateMaxPoints({
    required String quizDifficulty,
    required List<Map<String, dynamic>> questions,
  }) {
    int total = 0;

    for (var question in questions) {
      String questionDifficulty = question['difficulty'] ?? 'h1';
      total += _getPoints(quizDifficulty, questionDifficulty);
    }

    return total > 0 ? total : 1; // Prevent division by zero
  }

  /// Retrieves points based on quiz and question difficulties.
  int _getPoints(String quizDifficulty, String questionDifficulty) {
    Map<String, Map<String, int>> pointsTable = {
      'gf2': {
        'gf2': 100,
        'h1': 110,
        'h2': 120,
        'h3': 130,
        'h4': 140,
        'h5': 150,
      },
      'h1': {
        'gf2': 90,
        'h1': 100,
        'h2': 110,
        'h3': 120,
        'h4': 130,
        'h5': 140,
      },
      'h2': {
        'gf2': 80,
        'h1': 90,
        'h2': 100,
        'h3': 110,
        'h4': 120,
        'h5': 130,
      },
      'h3': {
        'gf2': 70,
        'h1': 80,
        'h2': 90,
        'h3': 100,
        'h4': 110,
        'h5': 120,
      },
      'h4': {
        'gf2': 60,
        'h1': 70,
        'h2': 80,
        'h3': 90,
        'h4': 100,
        'h5': 110,
      },
      'h5': {
        'gf2': 50,
        'h1': 60,
        'h2': 70,
        'h3': 80,
        'h4': 90,
        'h5': 100,
      },
    };

    // Normalize strings: lowercase and trim whitespace
    String normalizedQuizDifficulty = quizDifficulty.toLowerCase().trim();
    String normalizedQuestionDifficulty =
        questionDifficulty.toLowerCase().trim();

    // Debugging output
    print('Normalized Quiz Difficulty: $normalizedQuizDifficulty');
    print('Normalized Question Difficulty: $normalizedQuestionDifficulty');

    // Return points
    return pointsTable[normalizedQuizDifficulty]
            ?[normalizedQuestionDifficulty] ??
        0;
  }

  /// Displays an error dialog with the given title and message
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                isLoading = false;
              });
            },
          )
        ],
      ),
    );
  }

  /// Calculates the total number of pages based on the current displayed list
  int get totalPages => (displayedTakenTests.length / itemsPerPage).ceil();

  /// Retrieves the quizzes for the current page from the displayed list
  List<TakenTest> get paginatedTakenTests {
    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    endIndex = endIndex > displayedTakenTests.length
        ? displayedTakenTests.length
        : endIndex;
    return displayedTakenTests.sublist(startIndex, endIndex);
  }

  /// Navigates to the next page
  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
      });
    }
  }

  /// Navigates to the previous page
  void _previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
      });
    }
  }

  /// Performs search by calling the search endpoint and filtering the taken tests
  Future<void> _performSearch(String searchWord) async {
    if (searchWord.isEmpty) {
      // If search word is empty, reset to all taken tests
      setState(() {
        displayedTakenTests = allTakenTests;
        currentPage = 1;
        isSearching = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      currentPage = 1;
      isSearching = true;
    });

    final String searchUrl =
        'https://mercantec-quiz.onrender.com/api/Quizs/QuizSearch?searchWord=$searchWord';

    try {
      // Retrieve the JWT token from secure storage
      final token = await _secureStorage.readToken();
      if (token == null) {
        print('Error: Token not found');
        _showErrorDialog('Authentication Error', 'Please log in again.');
        return;
      }

      // Make the GET request with the JWT token in the headers
      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> searchResults = jsonDecode(response.body);

        // Extract quiz IDs from search results
        List<int> matchedQuizIDs = [];
        for (var quiz in searchResults) {
          if (quiz is Map<String, dynamic> && quiz['id'] != null) {
            matchedQuizIDs.add(int.parse(quiz['id'].toString()));
          }
        }

        // Filter the taken tests based on matched quiz IDs
        List<TakenTest> filteredTests = allTakenTests
            .where((test) => matchedQuizIDs.contains(test.quizID))
            .toList();

        setState(() {
          displayedTakenTests = filteredTests;
          isLoading = false;
        });
      } else {
        print('Search failed with status: ${response.statusCode}');
        _showErrorDialog('Search Error',
            'Failed to perform search. Please try again later.');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error during search: $e');
      _showErrorDialog('Network Error', 'An error occurred while searching.');
      setState(() {
        isLoading = false;
      });
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
          : RefreshIndicator(
              onRefresh: _fetchTakenTests,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                labelText: 'Search Tests',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.search),
                                  onPressed: () {
                                    _performSearch(
                                        _searchController.text.trim());
                                  },
                                ),
                              ),
                              onSubmitted: (value) {
                                _performSearch(value.trim());
                              },
                            ),
                          ),
                          if (isSearching)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                              },
                            ),
                        ],
                      ),
                    ),
                    // Display message if no tests are found
                    if (displayedTakenTests.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('Ingen gennemførte tests fundet.'),
                        ),
                      )
                    else
                      Expanded(
                        child: Column(
                          children: [
                            // List of Taken Tests
                            Expanded(
                              child: ListView.builder(
                                itemCount: paginatedTakenTests.length,
                                itemBuilder: (context, index) {
                                  final test = paginatedTakenTests[index];
                                  return Card(
                                    elevation: 3,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8, horizontal: 5),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 10, horizontal: 15),
                                      title: Text(
                                        test.testName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                      subtitle: Text(
                                          'Date Taken: ${test.formattedDate}'),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 10),
                                        decoration: BoxDecoration(
                                          color:
                                              test.score >= (test.maxPoints / 2)
                                                  ? Colors.green[100]
                                                  : Colors.red[100],
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          'Score: ${test.score} / ${test.maxPoints}',
                                          style: TextStyle(
                                            color: test.score >=
                                                    (test.maxPoints / 2)
                                                ? Colors.green[800]
                                                : Colors.red[800],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Pagination Controls
                            if (totalPages > 1)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed: currentPage > 1
                                          ? _previousPage
                                          : null,
                                      child: const Text('Previous'),
                                    ),
                                    const SizedBox(width: 20),
                                    Text('Page $currentPage of $totalPages'),
                                    const SizedBox(width: 20),
                                    ElevatedButton(
                                      onPressed: currentPage < totalPages
                                          ? _nextPage
                                          : null,
                                      child: const Text('Next'),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
