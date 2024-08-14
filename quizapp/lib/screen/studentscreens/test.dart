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
    },
  ];

  int currentQuestionIndex = 0;
  List<int?> selectedAnswers = [];

  @override
  void initState() {
    super.initState();
    selectedAnswers = List<int?>.filled(questions.length, null);
  }

  void _nextQuestion() {
    setState(() {
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
      } else {
        _showSubmitConfirmation();
      }
    });
  }

  void _previousQuestion() {
    setState(() {
      if (currentQuestionIndex > 0) {
        currentQuestionIndex--;
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
                Navigator.of(context).pop(); // Close the dialog
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
    final currentAnswers = questions[currentQuestionIndex]['answers'] as List<String>;
    final currentImage = questions[currentQuestionIndex]['image'];

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Question ${currentQuestionIndex + 1}/${questions.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                      backgroundColor: selectedAnswers[currentQuestionIndex] == index
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
                  onPressed: currentQuestionIndex > 0 ? _previousQuestion : null,
                  child: const Text('Back'),
                ),
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
    );
  }
}
