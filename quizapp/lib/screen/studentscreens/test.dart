// lib/screen/studentscreens/test.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quizapp/screen/studentscreens/testResults.dart';
import 'package:quizapp/services/flutter_secure_storage.dart'; // Corrected import

class Test extends StatefulWidget {
  final int quizID;

  const Test({Key? key, required this.quizID}) : super(key: key);

  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {
  List<Map<String, dynamic>> questions = []; // List of quiz questions
  int currentQuestionIndex = 0; // Current question index
  List<List<bool>> selectedAnswers = []; // User's selected answers
  bool isLoading = true; // Indicates if questions are loading
  bool isSubmitting = false; // Prevents multiple submissions
  String? quizDifficulty; // Stores the quiz's difficulty level

  final SecureStorageService _secureStorage = SecureStorageService();

  // Variables to track quiz timing
  late DateTime _quizStartTime;
  late DateTime _quizEndTime;

  @override
  void initState() {
    super.initState();
    _quizStartTime = DateTime.now();
    _fetchQuizDetailsAndQuestions();
  }

  // Fetch quiz details and questions from the API
  Future<void> _fetchQuizDetailsAndQuestions() async {
    try {
      final token = await _secureStorage.readToken();
      final userID = await _secureStorage.readUserID();

      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      if (userID == null) {
        throw Exception("User ID not found. Please log in again.");
      }

      // Fetch quiz details (including difficulty)
      final quizResponse = await http.get(
        Uri.parse(
            'https://mercantec-quiz.onrender.com/api/Quizs/${widget.quizID}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (quizResponse.statusCode != 200) {
        _showErrorDialog('Failed to fetch quiz details');
        return;
      }

      final Map<String, dynamic> quizData = jsonDecode(quizResponse.body);

      // Extract quiz difficulty
      quizDifficulty =
          quizData['difficulty'] ?? 'h1'; // Default to 'h1' if not provided

      // Fetch quiz-question pairs
      final quizQuestionResponse = await http.get(
        Uri.parse('https://mercantec-quiz.onrender.com/api/Quiz_Question'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (quizQuestionResponse.statusCode != 200) {
        _showErrorDialog('Failed to fetch quiz-question pairs');
        return;
      }

      final List<dynamic> quizQuestionPairs =
          jsonDecode(quizQuestionResponse.body);
      final List<int> questionIDs = quizQuestionPairs
          .where((pair) => pair['quizID'] == widget.quizID)
          .map<int>((pair) => int.parse(pair['questionID'].toString()))
          .toList();

      if (questionIDs.isEmpty) {
        _showErrorDialog("No questions found for the selected quiz.");
        return;
      }

      // Fetch all questions
      final questionResponse = await http.get(
        Uri.parse('https://mercantec-quiz.onrender.com/api/Questions'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (questionResponse.statusCode != 200) {
        _showErrorDialog('Failed to fetch questions');
        return;
      }

      final List<dynamic> allQuestions = jsonDecode(questionResponse.body);
      List<Map<String, dynamic>> fetchedQuestions = [];

      for (var questionData in allQuestions) {
        if (questionIDs.contains(int.parse(questionData['id'].toString()))) {
          // Parse correct answers as a list of indices (0-based)
          List<int> correctAnswerIndices = [];
          if (questionData['correctAnswer'] is List &&
              questionData['correctAnswer'].isNotEmpty) {
            correctAnswerIndices = List<int>.from(questionData['correctAnswer']
                .map((e) => e - 1)); // Adjust to 0-based
          } else if (questionData['correctAnswer'] is String) {
            correctAnswerIndices
                .add((int.tryParse(questionData['correctAnswer']) ?? 1) - 1);
          }

          fetchedQuestions.add({
            'question': questionData['title'] ?? 'No question text available',
            'answers': List<String>.from(questionData['possibleAnswers'] ?? []),
            'correctAnswerIndices': correctAnswerIndices,
            'timer': questionData['time'] ?? 30,
            'difficulty': questionData['difficulty'] ??
                'h1', // Ensure question difficulty is present
            'id': questionData['id'], // Include question ID for submission
          });
        }
      }

      setState(() {
        questions = fetchedQuestions;
        selectedAnswers = questions
            .map((q) => List<bool>.filled(q['answers'].length, false))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }

  // Toggle the selection state of an answer
  void _selectAnswer(int index) {
    setState(() {
      selectedAnswers[currentQuestionIndex][index] =
          !selectedAnswers[currentQuestionIndex][index];
    });
  }

  // Navigate to the next question or submit the quiz
  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });
    } else {
      _submitQuiz();
    }
  }

  // Submit the quiz
  void _submitQuiz() {
    // Record the quiz end time
    DateTime quizEndTime = DateTime.now();

    // Calculate time used in seconds
    int timeUsed = quizEndTime.difference(_quizStartTime).inSeconds;

    // Calculate the score (integer-based)
    int score = _calculateScore();

    // Navigate to TestResults screen without passing 'userID' and 'results'
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TestResults(
          selectedAnswers: selectedAnswers,
          questions: questions,
          quizDifficulty: quizDifficulty ?? 'h1', // Provide a default if null
          quizEndDate: quizEndTime.toUtc().toIso8601String(),
          completed: true,
          quizID: widget.quizID,
          timeUsed: timeUsed,
        ),
      ),
    );
  }

  /// Calculates the user's score based on correct answers.
  int _calculateScore() {
    int score = 0;

    for (int i = 0; i < questions.length; i++) {
      List<bool> selectedForQuestion = selectedAnswers[i];
      List<int> correctAnswerIndices =
          List<int>.from(questions[i]['correctAnswerIndices'] ?? []);

      // Get indices of selected answers
      List<int> selectedIndices = [];
      for (int j = 0; j < selectedForQuestion.length; j++) {
        if (selectedForQuestion[j]) {
          selectedIndices.add(j);
        }
      }

      // Debugging output
      print('Question ${i + 1}:');
      print('Selected Indices: $selectedIndices');
      print('Correct Indices: $correctAnswerIndices');

      // Check if selected indices match the correct answer indices
      if (_listsMatch(selectedIndices, correctAnswerIndices)) {
        score++;
      }
    }

    print('Total Score: $score/${questions.length}');
    return score;
  }

  /// Helper method to check if two lists contain the same elements, regardless of order.
  bool _listsMatch(List<int> list1, List<int> list2) {
    if (list1.length != list2.length) return false;
    for (int element in list1) {
      if (!list2.contains(element)) return false;
    }
    return true;
  }

  /// Show an error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                if (message.contains("No questions found") ||
                    message.contains("Token not found") ||
                    message.contains("User ID not found")) {
                  Navigator.of(context).pop(); // Exit the Test screen
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No questions available.')),
      );
    }

    final currentQuestion = questions[currentQuestionIndex]['question'];
    final currentAnswers =
        questions[currentQuestionIndex]['answers'] as List<String>;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentQuestionIndex + 1}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              currentQuestion,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: currentAnswers.asMap().entries.map((entry) {
                  int index = entry.key;
                  String answer = entry.value;
                  return CheckboxListTile(
                    title: Text(answer),
                    value: selectedAnswers[currentQuestionIndex][index],
                    onChanged: (bool? value) {
                      _selectAnswer(index);
                    },
                    activeColor: Colors.yellow,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _nextQuestion,
              child: Text(currentQuestionIndex < questions.length - 1
                  ? 'Next'
                  : 'Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
