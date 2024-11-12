import 'dart:math';
import 'package:flutter/material.dart';
import 'package:quizapp/screen/studentscreens/studentHome.dart';
import 'package:quizapp/services/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Entry point of the application.
void main() {
  runApp(const MyApp());
}

/// Root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const StudentHome(), // Initial page set to StudentHome
    );
  }
}

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
  final List<List<bool>> selectedAnswers; // Updated type
  final List<Map<String, dynamic>> questions;

  const TestResults({
    super.key,
    required this.selectedAnswers,
    required this.questions,
  });

  @override
  _TestResultsState createState() => _TestResultsState();
}

class _TestResultsState extends State<TestResults>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final bool _isUnderThreshold;
  final Random _random = Random();
  final int _emojiCount = 15;
  final SecureStorageService _secureStorage = SecureStorageService();

  // Add questions and selectedAnswers as class-level variables
  List<Map<String, dynamic>> questions = [];
  List<List<bool>> selectedAnswers = [];

  // List to hold properties of each emoji
  late final List<Emoji> _emojis;

  @override
  void initState() {
    super.initState();

    // Calculate the score
    int score = _calculateScore();

    // Determine if the score is under the threshold (50%)
    _isUnderThreshold = (score / widget.questions.length) < 0.5;

    // Initialize emojis with random properties
    _emojis = List.generate(_emojiCount, (_) {
      return Emoji(
        horizontalPosition: _random.nextDouble(),
        speed: 0.5 + _random.nextDouble(),
        initialDelay: _random.nextDouble(),
      );
    });

    // Set up the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat();

    // Stop the animation if not under threshold
    if (!_isUnderThreshold) {
      _controller.stop();
    }

    // Fetch questions with correct answers
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final token = await _secureStorage.readToken();
      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      final response = await http.get(
        Uri.parse('https://mercantec-quiz.onrender.com/api/Questions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          questions = data.map((item) {
            return {
              'id': item['id'],
              'question': item['title'],
              'possibleAnswers': List<String>.from(item['possibleAnswers']),
              'correctAnswer': List<int>.from(item['correctAnswer'] ?? []),
              'time': item['time'] ?? 30,
            };
          }).toList();

          // Initialize selectedAnswers based on the length of possible answers for each question
          selectedAnswers = questions
              .map((q) => List<bool>.filled(q['possibleAnswers'].length, false))
              .toList();
        });
      } else {
        print('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching questions: $e');
    }
  }

  /// Helper method to calculate the user's score.
  int _calculateScore() {
    int score = 0;

    for (int i = 0; i < widget.questions.length; i++) {
      List<bool> selectedForQuestion = widget.selectedAnswers[i];
      List<int> correctAnswerIndices =
          List<int>.from(widget.questions[i]['correctAnswer'] ?? []);

      // Get indices of selected answers
      List<int> selectedIndices = [];
      for (int j = 0; j < selectedForQuestion.length; j++) {
        if (selectedForQuestion[j]) {
          selectedIndices.add(j);
        }
      }

      // Check if selected indices match the correct answer indices
      if (_listsMatch(selectedIndices, correctAnswerIndices)) {
        score++;
      }
    }

    return score;
  }

  bool _listsMatch(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    for (int element in list1) {
      if (!list2.contains(element)) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
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
    // Recalculate the score to display (optional optimization: store in state)
    int score = _calculateScore();

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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Centers vertically
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Centers horizontally
              children: <Widget>[
                Text(
                  'Your Score: $score/${widget.questions.length}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 24),
                ),
                const SizedBox(height: 20),
                // Home Button
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const StudentHome()),
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
                ),
              ],
            ),
          ),
          // Falling emojis
          if (_isUnderThreshold)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Stack(
                      children: _emojis.map((emoji) {
                        double topPosition =
                            _calculateTopPosition(emoji, screenHeight);

                        // If the emoji has moved beyond the screen, reset its delay
                        if (topPosition > screenHeight) {
                          emoji.initialDelay = _random.nextDouble();
                          topPosition = 0;
                        }

                        return Positioned(
                          left: emoji.horizontalPosition * screenWidth,
                          top: topPosition,
                          child: const Text(
                            '😭',
                            style: TextStyle(fontSize: 30),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
