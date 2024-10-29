import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quizapp/screen/studentscreens/testResults.dart';

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
        body: const Test(),
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
  const Test({super.key});

  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'What is Flutter?',
      'answers': [
        'A mobile SDK',
        'A programming language',
        'A database',
        'An IDE'
      ],
      'correctAnswerIndex': 0,
      'image': 'assets/randers2.jpg',
      'timer': 10,
    },
    {
      'question': 'What is Dart?',
      'answers': [
        'A programming language',
        'A web framework',
        'A mobile SDK',
        'A game engine'
      ],
      'correctAnswerIndex': 0,
      'image': 'assets/john.jpg',
      'timer': 30,
    },
    {
      'question': 'Explain StatefulWidget in Flutter.',
      'answers': [
        'A widget with state',
        'A stateless widget',
        'A UI component',
        'A plugin'
      ],
      'correctAnswerIndex': 0,
      'image': null,
      'timer': 5,
    },
    {
      'question': 'What is a Widget in Flutter?',
      'answers': [
        'A UI component',
        'A database',
        'A mobile SDK',
        'A programming language'
      ],
      'correctAnswerIndex': 0,
      'image': 'assets/mike.jpg',
      'timer': 100,
    },
    {
      'question': 'What is the difference between hot reload and hot restart?',
      'answers': [
        'Hot reload updates UI instantly',
        'Hot restart restarts the app',
        'Both restart the app',
        'Both refresh the UI'
      ],
      'correctAnswerIndex': 0,
      'image': 'assets/randers3.jpg',
      'timer': 40,
    },
  ];

  int currentQuestionIndex = 0;
  List<int?> selectedAnswers = [];
  late int _timeRemaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    selectedAnswers = List<int?>.filled(questions.length, null);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
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

  void _nextQuestion() {
    setState(() {
      if (currentQuestionIndex < questions.length - 1) {
        // Automatically mark the current question as unanswered if no answer is selected
        if (selectedAnswers[currentQuestionIndex] == null) {
          selectedAnswers[currentQuestionIndex] =
              -1; // or any default value indicating no answer
        }

        currentQuestionIndex++;
        _startTimer(); // Restart the timer for the next question
      } else {
        // Automatically submit if it's the last question
        _submitQuiz();
      }
    });
  }

  void _selectAnswer(int index) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = index;
    });
  }

  void _showSubmitConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Submission'),
          content: const Text('Are you sure you want to submit your answers?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitQuiz(); // Submit the quiz
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _submitQuiz() {
    _timer?.cancel(); // Stop the timer when the quiz is submitted
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

  @override
  Widget build(BuildContext context) {
    final currentQuestion = questions[currentQuestionIndex]['question'];
    final currentAnswers =
        questions[currentQuestionIndex]['answers'] as List<String>;
    final currentImage = questions[currentQuestionIndex]['image'];

    return Scaffold(
      appBar: AppBar(
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
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Question ${currentQuestionIndex + 1}/${questions.length}',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
              const SizedBox(height: 20),
              Text(
                currentQuestion,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              if (currentImage != null)
                Container(
                  constraints: const BoxConstraints(
                    maxHeight: 280,
                    maxWidth: double.infinity,
                  ),
                  child: Image.asset(
                    currentImage,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Text('Image not available'),
                      );
                    },
                  ),
                ),
              if (currentImage != null) const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _nextQuestion,
                    child: Text(currentQuestionIndex < questions.length - 1
                        ? 'Next'
                        : 'Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
