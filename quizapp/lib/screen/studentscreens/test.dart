import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quizapp/screen/studentscreens/testResults.dart';
import 'package:quizapp/services/flutter_secure_storage.dart';

class Test extends StatefulWidget {
  final int quizID;

  const Test({Key? key, required this.quizID}) : super(key: key);

  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0;
  List<List<bool>> selectedAnswers = [];
  late int _timeRemaining;
  Timer? _timer;
  bool isLoading = true;

  final SecureStorageService _secureStorage = SecureStorageService();

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
          // Parse correct answers as a list of indices and adjust to 0-based indexing
          List<int> correctAnswerIndices = [];
          if (questionData['correctAnswer'] is List &&
              questionData['correctAnswer'].isNotEmpty) {
            correctAnswerIndices = List<int>.from(
                questionData['correctAnswer'].map((e) => e - 1)); // Adjust here
          } else if (questionData['correctAnswer'] is String) {
            correctAnswerIndices
                .add((int.tryParse(questionData['correctAnswer']) ?? 1) - 1);
          }

          fetchedQuestions.add({
            'question': questionData['title'] ?? 'No question text available',
            'answers': List<String>.from(questionData['possibleAnswers'] ?? []),
            'correctAnswerIndices': correctAnswerIndices,
            'timer': questionData['time'] ?? 30,
          });

          // Debugging: Print the question and correct answers
          print("Question: ${questionData['title']}");
          print("Correct Answers (adjusted): $correctAnswerIndices");
        }
      }

      setState(() {
        questions = fetchedQuestions;
        selectedAnswers = questions
            .map((q) => List<bool>.filled(q['answers'].length, false))
            .toList();
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
        currentQuestionIndex++;
        _startTimer();
      } else {
        _submitQuiz();
      }
    });
  }

  void _selectAnswer(int index) {
    setState(() {
      selectedAnswers[currentQuestionIndex][index] =
          !selectedAnswers[currentQuestionIndex][index];
    });
  }

  void _submitQuiz() async {
    _timer?.cancel();

    // Debugging: Print selected and correct answers
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final selectedForQuestion = selectedAnswers[i];
      final correctAnswers = question['correctAnswerIndices'];

      // Get selected indices
      List<int> selectedIndices = [];
      for (int j = 0; j < selectedForQuestion.length; j++) {
        if (selectedForQuestion[j]) {
          selectedIndices.add(j);
        }
      }

      print("Question ${i + 1}: ${question['question']}");
      print("Selected Answers: $selectedIndices");
      print("Correct Answers (adjusted): $correctAnswers");
    }

    await _submitQuizResults();

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

  Future<void> _submitQuizResults() async {
    const String url = 'https://mercantec-quiz.onrender.com/api/User_Quiz';
    final quizEndDate = DateTime.now().toUtc().toIso8601String();
    final completed = true;
    final results = calculateResults();
    final quizID = widget.quizID;
    final userIDString = await _secureStorage.readUserID();
    final userID = int.tryParse(userIDString ?? '0') ?? 0;
    final timeUsed = calculateTimeUsed();

    final Map<String, dynamic> payload = {
      "quizEndDate": quizEndDate,
      "completed": completed,
      "results": results,
      "quizID": quizID,
      "userID": userID,
      "timeUsed": timeUsed,
    };

    _timer?.cancel();

    // Debugging: Print selected and correct answers
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final selectedForQuestion = selectedAnswers[i];
      final correctAnswers = question['correctAnswerIndices'];

      // Get selected indices
      List<int> selectedIndices = [];
      for (int j = 0; j < selectedForQuestion.length; j++) {
        if (selectedForQuestion[j]) {
          selectedIndices.add(j);
        }
      }

      print("Question ${i + 1}: ${question['question']}");
      print("Selected Answers: $selectedIndices");
      print("Correct Answers: $correctAnswers");
    }

    await _submitQuizResults();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestResults(
          selectedAnswers: selectedAnswers,
          questions: questions,
        ),
      ),
    );

    try {
      final token = await _secureStorage.readToken();
      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Quiz results submitted successfully');
      } else {
        print('Failed to submit quiz results');
      }
    } catch (e) {
      print('Error submitting quiz results: $e');
    }
  }

  int calculateResults() {
    int score = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i].contains(true)) {
        score++;
      }
    }
    return score;
  }

  int calculateTimeUsed() {
    return 0; // Placeholder
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
                      backgroundColor: selectedAnswers[currentQuestionIndex]
                              [index]
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
