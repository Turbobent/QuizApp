// lib/screen/studentscreens/takenTests.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quizapp/services/flutter_secure_storage.dart';
import 'package:intl/intl.dart'; // Imported intl for date formatting

// Model class for a taken test
class TakenTest {
  final int quizID;
  final String testName;
  final String dateTaken;
  final int score;

  TakenTest({
    required this.quizID,
    required this.testName,
    required this.dateTaken,
    required this.score,
  });

  // Factory constructor to create a TakenTest instance from JSON
  factory TakenTest.fromJson(Map<String, dynamic> json) {
    return TakenTest(
      quizID: json['quiz']['id'] != null
          ? int.parse(json['quiz']['id'].toString())
          : 0,
      testName: json['quiz']['title'] ?? 'Unknown Title',
      dateTaken: json['quizEndDate'] ?? 'Unknown Date',
      score: json['results'] ?? 0,
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

  /// Fetches the list of taken tests
  Future<void> _fetchTakenTests() async {
    setState(() {
      isLoading = true;
      currentPage = 1; // Reset to first page on refresh
    });

    final userIdString = await _secureStorage.readUserID();
    print('Retrieved userIdString: $userIdString'); // Debug statement

    final int userId = int.tryParse(userIdString ?? '0') ?? 0;
    print('Parsed userId: $userId'); // Debug statement

    if (userId == 0) {
      _showErrorDialog(
        'Invalid User ID',
        'Failed to retrieve a valid user ID. Please log in again.',
      );
      return;
    }

    final String url =
        'https://mercantec-quiz.onrender.com/api/User_Quiz/AllUserQuiz/$userId';
    print('Constructed URL: $url'); // Debug statement

    try {
      final token = await _secureStorage.readToken();
      if (token == null) {
        print('Error: Token not found');
        _showErrorDialog('Authentication Error', 'Please log in again.');
        return;
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('API Response Status: ${response.statusCode}'); // Debug statement

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print('API Response Data: $data'); // Debug statement

        final completedTests =
            data.where((item) => item['completed'] == true).toList();
        print('Completed Tests: $completedTests'); // Debug statement

        if (completedTests.isEmpty) {
          setState(() {
            allTakenTests = [];
            displayedTakenTests = [];
            isLoading = false;
            isSearching = false;
          });
          return;
        }

        List<TakenTest> fetchedTakenTests = completedTests
            .map((test) => TakenTest.fromJson(test))
            .where((test) => test.quizID != 0)
            .toList();

        setState(() {
          allTakenTests = fetchedTakenTests;
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
    print('Search URL: $searchUrl'); // Debug statement

    try {
      final token = await _secureStorage.readToken();
      if (token == null) {
        print('Error: Token not found');
        _showErrorDialog('Authentication Error', 'Please log in again.');
        return;
      }

      final response = await http.get(
        Uri.parse(searchUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print(
          'Search API Response Status: ${response.statusCode}'); // Debug statement

      if (response.statusCode == 200) {
        final List<dynamic> searchResults = jsonDecode(response.body);
        print('Search Results: $searchResults'); // Debug statement

        // Extract quiz IDs from search results
        List<int> matchedQuizIDs = [];
        for (var quiz in searchResults) {
          if (quiz is Map<String, dynamic> && quiz['id'] != null) {
            matchedQuizIDs.add(int.parse(quiz['id'].toString()));
          }
        }
        print('Matched Quiz IDs: $matchedQuizIDs'); // Debug statement

        // Filter the taken tests based on matched quiz IDs
        List<TakenTest> filteredTests = allTakenTests
            .where((test) => matchedQuizIDs.contains(test.quizID))
            .toList();
        print('Filtered Tests: $filteredTests'); // Debug statement

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
                                          color: Colors.blue[100],
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          '${test.score}%',
                                          style: TextStyle(
                                            color: Colors.blue[800],
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
