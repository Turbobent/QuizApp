import 'package:flutter/material.dart';

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
    );
  }
}

class Test extends StatefulWidget {
  const Test({super.key});

  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {
  // Hardcoded list of questions, answers, and images
  final List<Map<String, dynamic>> questions = [
    {
      'question': 'What is Flutter?',
      'answers': [
        'A mobile SDK',
        'A programming language',
        'A database',
        'An IDE'
      ],
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
      'image': null, // No image for this question
    },
    {
      'question': 'What is a Widget in Flutter?',
      'answers': [
        'A UI component',
        'A database',
        'A mobile SDK',
        'A programming language'
      ],
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
      'image': 'assets/randers3.jpg',
    },
  ];

  // Index to keep track of the current question
  int currentQuestionIndex = 0;

  // List to store the selected answer index for each question
  List<int?> selectedAnswers = [];

  @override
  void initState() {
    super.initState();
    // Initialize the selectedAnswers list with null values for each question
    selectedAnswers = List<int?>.filled(questions.length, null);
  }

  // Function to move to the next question
  void _nextQuestion() {
    setState(() {
      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
      } else {
        // Handle the submission of the quiz here
        _submitQuiz();
      }
    });
  }

  // Function to move to the previous question
  void _previousQuestion() {
    setState(() {
      if (currentQuestionIndex > 0) {
        currentQuestionIndex--;
      }
    });
  }

  // Function to handle answer selection
  void _selectAnswer(int index) {
    setState(() {
      selectedAnswers[currentQuestionIndex] = index; // Save the selected answer
    });
  }

  // Function to handle quiz submission
  void _submitQuiz() {
    // Here you can process the selected answers, such as calculating the score
    // For now, we just show a dialog with the selected answers
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quiz Completed'),
        content: Text('Selected Answers: $selectedAnswers'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current question, answers, and image
    final currentQuestion = questions[currentQuestionIndex]['question'];
    final currentAnswers =
        questions[currentQuestionIndex]['answers'] as List<String>;
    final currentImage = questions[currentQuestionIndex]['image'];

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: SingleChildScrollView(
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
            // Conditionally display the image if it's available
            if (currentImage != null)
              Container(
                constraints: const BoxConstraints(
                  maxHeight: 280, // Maximum height of the image
                  maxWidth:
                      double.infinity, // Ensure it uses full width available
                ),
                child: Image.asset(
                  currentImage,
                  fit: BoxFit
                      .contain, // Ensures the image covers the box without distortion
                  errorBuilder: (context, error, stackTrace) {
                    // Handle cases where the image cannot be loaded
                    return const Center(
                      child: Text('Image not available'),
                    );
                  },
                ),
              ),
            if (currentImage != null) const SizedBox(height: 20),
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
                      _selectAnswer(index);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          selectedAnswers[currentQuestionIndex] == index
                              ? Colors.yellow
                              : null, // Change the color if selected
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
                  onPressed:
                      currentQuestionIndex > 0 ? _previousQuestion : null,
                  child: const Text('Back'),
                ),
                // Next Button
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
