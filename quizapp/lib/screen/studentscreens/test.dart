import 'package:flutter/material.dart';

void main() => runApp(const TestApp());

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('test name'),
        ),
        body: const Test(),
      ),
    );
  }
}

class Test extends StatefulWidget {
  const Test({super.key});

  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {
  // Hardcoded list of questions and answers
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'What is Flutter?',
      'answers': ['1: A mobile SDK', '2: A programming language', '3: A database', '4: An IDE']
    },
    {
      'question': 'What is Dart?',
      'answers': ['A programming language', 'A web framework', 'A mobile SDK', 'A game engine']
    },
    {
      'question': 'Explain StatefulWidget in Flutter.',
      'answers': ['A widget with state', 'A stateless widget', 'A UI component', 'A plugin']
    },
    {
      'question': 'What is a Widget in Flutter?',
      'answers': ['A UI component', 'A database', 'A mobile SDK', 'A programming language']
    },
    {
      'question': 'What is the difference between hot reload and hot restart?',
      'answers': ['Hot reload updates UI instantly', 'Hot restart restarts the app', 'Both restart the app', 'Both refresh the UI' ]
    },
  ];

  // Index to keep track of the current question
  int currentQuestionIndex = 0;

  // Index to keep track of the selected answer
  int? selectedAnswerIndex;

  // Function to move to the next question
  void _nextQuestion() {
    setState(() {
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
        selectedAnswerIndex = null; // Reset the selected answer
      }
    });
  }

  // Function to move to the previous question
  void _previousQuestion() {
    setState(() {
      if (currentQuestionIndex > 0) {
        currentQuestionIndex--;
        selectedAnswerIndex = null; // Reset the selected answer
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the current question and answers
    final currentQuestion = questions[currentQuestionIndex]['question'];
    final currentAnswers = questions[currentQuestionIndex]['answers'] as List<String>;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Display the current question
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
          // Display the list of answers
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: currentAnswers.asMap().entries.map((entry) {
              int index = entry.key;
              String answer = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedAnswerIndex = index; // Update the selected answer index
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedAnswerIndex == index ? Colors.yellow : null, // Change the color if selected
                  ),
                  child: Text(answer),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
          // Row for the buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              // Back Button
              ElevatedButton(
                onPressed: currentQuestionIndex > 0 ? _previousQuestion : null,
                child: const Text('Back'),
              ),
              // Next Button
              ElevatedButton(
                onPressed: currentQuestionIndex < questions.length - 1
                    ? _nextQuestion
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
