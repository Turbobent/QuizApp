import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quizapp/screen/studentscreens/testResults.dart';
import 'package:quizapp/services/flutter_secure_storage.dart'; // Import the secure storage service

void main() => runApp(const TestApp());

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Quiz App'),
        ),
        body: const Test(quizID: 0), // Pass a default quizID for testing
      ),
      routes: {
        '/testResults': (context) => const TestResults(
              selectedAnswers: [],
              questions: [],
            ),
      },
    );
  }
}

class Test extends StatefulWidget {
  final int quizID;
  const Test({Key? key, required this.quizID}) : super(key: key);

  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  List<int?> selectedAnswers = [];
  late int _timeRemaining;
  Timer? _timer;
  bool isLoading = true;

  final SecureStorageService _secureStorage =
      SecureStorageService(); // Initialize secure storage

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  Future<void> _fetchQuestions() async {
    try {
      final token = await _secureStorage.readToken();

      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      // Step 1: Fetch all Quiz-Question pairs
      final quizQuestionResponse = await http.get(
        Uri.parse('https://mercantec-quiz.onrender.com/api/Quiz_Question'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (quizQuestionResponse.statusCode != 200) {
        _showErrorDialog(
            'Failed to fetch quiz-question pairs: ${quizQuestionResponse.statusCode}');
        return;
      }

      // Parse and filter quiz-question pairs by selected quizID to get questionIDs
      final List<dynamic> quizQuestionPairs =
          jsonDecode(quizQuestionResponse.body);
      final List<int> questionIDs = quizQuestionPairs
          .where((pair) => pair['quizID'] == widget.quizID)
          .map<int>((pair) => int.parse(
              pair['questionID'].toString())) // Ensure questionID is an int
          .toList();

      if (questionIDs.isEmpty) {
        _showErrorDialog("No questions found for the selected quiz.");
        return;
      }

      // Step 2: Fetch all questions from /api/Questions in one batch
      final questionResponse = await http.get(
        Uri.parse('https://mercantec-quiz.onrender.com/api/Questions'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (questionResponse.statusCode != 200) {
        _showErrorDialog(
            'Failed to fetch questions: ${questionResponse.statusCode}');
        return;
      }

      // Parse all questions and filter only those with matching questionIDs
      final List<dynamic> allQuestions = jsonDecode(questionResponse.body);
      List<Map<String, dynamic>> fetchedQuestions = [];

      for (var questionData in allQuestions) {
        // Check if this question's ID is in the list of relevant questionIDs
        if (questionIDs.contains(int.parse(questionData['id'].toString()))) {
          // Print question data for debugging
          print('Fetched question data: $questionData');

          // Parse the correct answer index safely
          int correctAnswerIndex = -1;
          if (questionData['correctAnswer'] is List) {
            if (questionData['correctAnswer'].isNotEmpty) {
              correctAnswerIndex =
                  int.tryParse(questionData['correctAnswer'][0].toString()) ??
                      -1;
            }
          } else if (questionData['correctAnswer'] is String) {
            correctAnswerIndex =
                int.tryParse(questionData['correctAnswer']) ?? -1;
          }

          // Add parsed question data to the list
          fetchedQuestions.add({
            'question': questionData['title'] ?? 'No question text available',
            'answers': List<String>.from(questionData['possibleAnswers'] ?? []),
            'correctAnswerIndex': correctAnswerIndex,
            'timer': questionData['time'] ?? 30,
          });
        }
      }

      // Step 3: Update the state with fetched questions
      setState(() {
        questions = fetchedQuestions;
        selectedAnswers = List<int?>.filled(questions.length, null);
        isLoading = false;
        _startTimer();
      });
    } catch (e) {
      _showErrorDialog('An error occurred: $e');
    }
  }

  void _startTimer() {
    if (questions.isNotEmpty) {
      _timeRemaining = questions[currentQuestionIndex]['timer'];
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timeRemaining > 0) {
          setState(() {
            _timeRemaining--;
          });
        } else {
          _nextQuestion();
        }
      });
    }
  }

  void _nextQuestion() {
    setState(() {
      if (currentQuestionIndex < questions.length - 1) {
        if (selectedAnswers[currentQuestionIndex] == null) {
          selectedAnswers[currentQuestionIndex] = -1;
        }

        currentQuestionIndex++;
        _startTimer();
      } else {
        _submitQuiz();
      }
    });
  }

  void _selectAnswer(int index) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = index;
    });
  }

  void _submitQuiz() {
    _timer?.cancel();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestResults(
          selectedAnswers: selectedAnswers,
          questions: questions,
        ),
      ),
    );
  }

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
      return const Center(child: CircularProgressIndicator());
    }

    if (questions.isEmpty) {
      return const Center(child: Text('No questions available.'));
    }

    final currentQuestion = questions[currentQuestionIndex]['question'];
    final currentAnswers =
        questions[currentQuestionIndex]['answers'] as List<String>;

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentQuestionIndex + 1}'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Center(
              child: Text(
                'Time: $_timeRemaining',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
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
            Column(
              children: currentAnswers.asMap().entries.map((entry) {
                int index = entry.key;
                String answer = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _selectAnswer(index);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedAnswers[currentQuestionIndex] == index
                              ? Colors.yellow
                              : null,
                    ),
                    child: Text(answer),
                  ),
                );
              }).toList(),
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
