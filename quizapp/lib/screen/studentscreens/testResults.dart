// lib/screen/studentscreens/testResults.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:quizapp/screen/studentscreens/studentHome.dart';
import 'package:quizapp/services/flutter_secure_storage.dart'; // Ensure this import exists
import 'package:http/http.dart' as http;
import 'dart:math';
import 'dart:io';

/// Model class to hold properties for each falling emoji.
class Emoji {
  double horizontalPosition; // Fraction of screen width (0.0 - 1.0)
  double speed; // Speed multiplier
  double initialDelay; // Delay as a fraction of the animation duration

  Emoji({
    required this.horizontalPosition,
    required this.speed,
    required this.initialDelay,
  });
}

/// Stateful widget to display test results and falling emojis if under threshold.
class TestResults extends StatefulWidget {
  final List<List<bool>> selectedAnswers; // User's selected answers
  final List<Map<String, dynamic>> questions; // List of quiz questions
  final String quizDifficulty; // Quiz difficulty level

  // Additional fields for submission
  final String quizEndDate;
  final bool completed;
  final int quizID;
  final int timeUsed;

  const TestResults({
    Key? key,
    required this.selectedAnswers,
    required this.questions,
    required this.quizDifficulty,
    required this.quizEndDate,
    required this.completed,
    required this.quizID,
    required this.timeUsed,
  }) : super(key: key);

  @override
  _TestResultsState createState() => _TestResultsState();
}

class _TestResultsState extends State<TestResults>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isUnderThreshold = false;
  final SecureStorageService _secureStorage = SecureStorageService();
  final Random _random = Random();
  final int _emojiCount = 15;

  // List to hold properties of each emoji
  late final List<Emoji> _emojis;

  // Store the total points and max points in state variables
  late int _totalPoints;
  late int _maxPoints;

  bool _isSubmitting = true; // Indicates if the PUT request is in progress
  String? _submissionError; // Stores any submission errors

  int _userID = 0; // Variable to store userID

  @override
  void initState() {
    super.initState();

    // Initialize emojis with random properties
    _emojis = List.generate(_emojiCount, (_) {
      return Emoji(
        horizontalPosition: _random.nextDouble(),
        speed: 0.5 + _random.nextDouble(), // Speed between 0.5x to 1.5x
        initialDelay: _random.nextDouble(), // Delay between 0.0 to 1.0
      );
    });

    // Set up the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    // Start the PUT request
    _submitQuizResults();
  }

  /// Performs the PUT request to submit quiz results
  Future<void> _submitQuizResults() async {
    try {
      final token = await _secureStorage.readToken();

      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      // Retrieve userID from secure storage
      String? userIdString = await _secureStorage.readUserID();
      _userID = int.tryParse(userIdString ?? '') ?? 0;

      if (_userID == 0) {
        throw Exception("Invalid user ID. Please log in again.");
      }

      // Calculate the total points before constructing the payload
      _totalPoints = _calculateTotalPoints();

      // Calculate maximum possible points
      _maxPoints = _calculateMaxPoints();

      // Determine if the score is under the threshold (50%)
      _isUnderThreshold = (_totalPoints / _maxPoints) < 0.5;

      // Prepare the payload with the correct results
      Map<String, dynamic> payload = {
        "quizEndDate": widget.quizEndDate,
        "completed": widget.completed,
        "results": _totalPoints, // Use the calculated total points
        "quizID": widget.quizID,
        "userID": _userID, // Use the retrieved userID
        "timeUsed": widget.timeUsed,
      };

      // **Print the payload for debugging**
      print('Payload being sent: ${jsonEncode(payload)}');

      // Make the PUT request to User_Quiz endpoint
      final response = await http.put(
        Uri.parse('https://mercantec-quiz.onrender.com/api/User_Quiz'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Submission successful
        print('Quiz submission successful: ${response.body}');
      } else {
        // Handle server errors
        String errorMsg =
            'Failed to submit quiz. Server responded with status code ${response.statusCode}.';
        if (response.body.isNotEmpty) {
          errorMsg += ' Message: ${response.body}';
        }
        throw Exception(errorMsg);
      }
    } on SocketException {
      setState(() {
        _submissionError = 'No Internet connection. Please check your network.';
      });
      print('Error submitting quiz: No Internet connection.');
    } on HttpException {
      setState(() {
        _submissionError = 'Server error. Please try again later.';
      });
      print('Error submitting quiz: Server error.');
    } on FormatException {
      setState(() {
        _submissionError =
            'Invalid data format received from server. Please contact support.';
      });
      print('Error submitting quiz: Invalid data format.');
    } catch (e) {
      setState(() {
        _submissionError = 'An unexpected error occurred: $e';
      });
      print('Error submitting quiz: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });

      // Calculate maximum possible points (redundant if already done above)
      // _maxPoints is already calculated before

      // Re-determine if the score is under the threshold (in case maxPoints was 0)
      _isUnderThreshold =
          _maxPoints > 0 ? (_totalPoints / _maxPoints) < 0.5 : false;

      if (_isUnderThreshold) {
        // Start the animation
        if (!_controller.isAnimating) {
          _controller.repeat();
        }
      } else {
        // Stop the animation
        if (_controller.isAnimating) {
          _controller.stop();
        }
      }
    }
  }

  /// Calculates the total points based on quiz and question difficulties.
  int _calculateTotalPoints() {
    int total = 0;

    for (int i = 0; i < widget.questions.length; i++) {
      String questionDifficulty = widget.questions[i]['difficulty'];
      bool isCorrect = _isAnswerCorrect(i);

      // Debugging outputs
      print('Quiz Difficulty: ${widget.quizDifficulty}');
      print('Question ${i + 1} Difficulty: $questionDifficulty');
      print('Is Correct: $isCorrect');

      if (isCorrect) {
        int points = _getPoints(widget.quizDifficulty, questionDifficulty);
        print('Points for Question ${i + 1}: $points');
        total += points;
      }
    }

    print('Total Points: $total');
    return total;
  }

  /// Determines if the selected answers for a question are correct.
  bool _isAnswerCorrect(int questionIndex) {
    List<bool> selectedForQuestion = widget.selectedAnswers[questionIndex];
    List<int> correctAnswerIndices = List<int>.from(
        widget.questions[questionIndex]['correctAnswerIndices'] ?? []);

    // Get indices of selected answers
    List<int> selectedIndices = [];
    for (int j = 0; j < selectedForQuestion.length; j++) {
      if (selectedForQuestion[j]) {
        selectedIndices.add(j);
      }
    }

    // Check if selected indices match the correct answer indices
    return _listsMatch(selectedIndices, correctAnswerIndices);
  }

  /// Helper method to check if two lists contain the same elements, regardless of order.
  bool _listsMatch(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    for (int element in list1) {
      if (!list2.contains(element)) return false;
    }
    return true;
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

  /// Calculates the maximum possible points for the quiz.
  int _calculateMaxPoints() {
    int max = 0;

    for (var question in widget.questions) {
      String questionDifficulty = question['difficulty'];
      int points = _getPoints(widget.quizDifficulty, questionDifficulty);
      max += points;
    }

    print('Maximum Points: $max');
    return max > 0 ? max : 1; // Prevent division by zero
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the animation controller
    super.dispose();
  }

  /// Calculates the vertical position of an emoji based on the animation value.
  double _calculateTopPosition(Emoji emoji, double screenHeight) {
    // Adjust the animation value with the emoji's initial delay
    double animationValue = (_controller.value + emoji.initialDelay) % 1.0;

    // Calculate the vertical position
    return animationValue * screenHeight * emoji.speed;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
      ),
      body: Stack(
        children: [
          // Main content
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : _submissionError != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error,
                                color: Colors.red, size: 60),
                            const SizedBox(height: 20),
                            Text(
                              'Error submitting quiz:\n$_submissionError',
                              style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const StudentHome()),
                                  (Route<dynamic> route) => false,
                                );
                              },
                              child: const Text('Return to Home'),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Your Score: $_totalPoints / $_maxPoints',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 24),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Percentage: ${_calculatePercentage()}%',
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal, fontSize: 18),
                            ),
                            const SizedBox(height: 20),
                            // Home Button
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const StudentHome()),
                                  (route) => false,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 50, vertical: 20),
                              ),
                              child: const Text(
                                'Home',
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ],
                        ),  
            ),
          ),
          // Falling emojis
          // if (!_isSubmitting && _submissionError == null && _isUnderThreshold)
            // Positioned.fill(
            //   child: IgnorePointer(
            //     child: AnimatedBuilder(
            //       animation: _controller,
            //       builder: (context, child) {
            //         return Stack(
            //           children: _emojis.map((emoji) {
            //             double topPosition =
            //                 _calculateTopPosition(emoji, screenHeight);
          // if (_isUnderThreshold)
          //   Positioned.fill(
          //     child: IgnorePointer(
          //       child: AnimatedBuilder(
          //         animation: _controller,
          //         builder: (context, child) {
          //           return Stack(
          //             children: _emojis.map((emoji) {
          //               double topPosition =
          //                   _calculateTopPosition(emoji, screenHeight);

          //               // If the emoji has moved beyond the screen, reset its delay
          //               if (topPosition > screenHeight) {
          //                 emoji.initialDelay = _random.nextDouble();
          //                 topPosition = 0;
          //               }

          //               return Positioned(
          //                 left: emoji.horizontalPosition * screenWidth,
          //                 top: topPosition,
          //                 child: const Text(
          //                   '😭',
          //                   style: TextStyle(fontSize: 30),
          //                 ),
          //               );
          //             }).toList(),
          //           );
          //         },
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }

  /// Calculates the user's score as a percentage.
  double _calculatePercentage() {
    if (_maxPoints == 0) return 0.0;
    return ((_totalPoints / _maxPoints) * 100).toDoubleAsFixed(2);
  }
}

extension DoubleExtension on double {
  /// Rounds a double to two decimal places.
  double toDoubleAsFixed(int fractionDigits) {
    return double.parse(toStringAsFixed(fractionDigits));
  }
}
