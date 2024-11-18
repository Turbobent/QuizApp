// lib/screen/studentscreens/test.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quizapp/screen/studentscreens/testResults.dart';
import 'package:quizapp/services/flutter_secure_storage.dart'; // Korrekt import

class Test extends StatefulWidget {
  final int quizID;

  const Test({Key? key, required this.quizID}) : super(key: key);

  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {
  List<Map<String, dynamic>> questions = []; // Liste af quizspørgsmål
  int currentQuestionIndex = 0; // Nuværende spørgsmål indeks
  List<List<bool>> selectedAnswers = []; // Brugerens valgte svar
  bool isLoading = true; // Indikerer om spørgsmål indlæses
  bool isSubmitting = false; // Forhindrer multiple indsendelser
  String? quizDifficulty; // Gemmer quizsværhedsgraden

  final SecureStorageService _secureStorage = SecureStorageService();

  // Variabler til at spore quiz tidsforbrug
  late DateTime _quizStartTime;
  late DateTime _quizEndTime;

  // Timer relaterede variabler
  int _remainingTime = 0; // Resterende tid i sekunder
  Timer? _timer; // Timer objekt

  @override
  void initState() {
    super.initState();
    _quizStartTime = DateTime.now();
    _fetchQuizDetailsAndQuestions();
  }

  // Hent quiz detaljer og spørgsmål fra API'en
  Future<void> _fetchQuizDetailsAndQuestions() async {
    try {
      final token = await _secureStorage.readToken();
      final userID = await _secureStorage.readUserID();

      if (token == null) {
        throw Exception("Token ikke fundet. Log venligst ind igen.");
      }

      if (userID == null) {
        throw Exception("User ID ikke fundet. Log venligst ind igen.");
      }

      // Hent quiz detaljer (inklusive sværhedsgrad)
      final quizResponse = await http.get(
        Uri.parse(
            'https://mercantec-quiz.onrender.com/api/Quizs/${widget.quizID}'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (quizResponse.statusCode != 200) {
        _showErrorDialog('Kunne ikke hente quiz detaljer');
        return;
      }

      final Map<String, dynamic> quizData = jsonDecode(quizResponse.body);

      // Uddrag quiz sværhedsgrad
      quizDifficulty =
          quizData['difficulty'] ?? 'h1'; // Standard til 'h1' hvis ikke angivet

      // Hent quiz-spørgsmål par
      final quizQuestionResponse = await http.get(
        Uri.parse('https://mercantec-quiz.onrender.com/api/Quiz_Question'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (quizQuestionResponse.statusCode != 200) {
        _showErrorDialog('Kunne ikke hente quiz-spørgsmål par');
        return;
      }

      final List<dynamic> quizQuestionPairs =
          jsonDecode(quizQuestionResponse.body);
      final List<int> questionIDs = quizQuestionPairs
          .where((pair) => pair['quizID'] == widget.quizID)
          .map<int>((pair) => int.parse(pair['questionID'].toString()))
          .toList();

      if (questionIDs.isEmpty) {
        _showErrorDialog("Ingen spørgsmål fundet for den valgte quiz.");
        return;
      }

      // Hent alle spørgsmål
      final questionResponse = await http.get(
        Uri.parse('https://mercantec-quiz.onrender.com/api/Questions'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (questionResponse.statusCode != 200) {
        _showErrorDialog('Kunne ikke hente spørgsmål');
        return;
      }

      final List<dynamic> allQuestions = jsonDecode(questionResponse.body);
      List<Map<String, dynamic>> fetchedQuestions = [];

      for (var questionData in allQuestions) {
        if (questionIDs.contains(int.parse(questionData['id'].toString()))) {
          // Pars korrekte svar som en liste af indekser (0-baseret)
          List<int> correctAnswerIndices = [];
          if (questionData['correctAnswer'] is List &&
              questionData['correctAnswer'].isNotEmpty) {
            correctAnswerIndices = List<int>.from(questionData['correctAnswer']
                .map((e) => e - 1)); // Juster til 0-baseret
          } else if (questionData['correctAnswer'] is String) {
            correctAnswerIndices
                .add((int.tryParse(questionData['correctAnswer']) ?? 1) - 1);
          }

          fetchedQuestions.add({
            'question':
                questionData['title'] ?? 'Ingen spørgsmålstekst tilgængelig',
            'answers': List<String>.from(questionData['possibleAnswers'] ?? []),
            'correctAnswerIndices': correctAnswerIndices,
            'timer': questionData['time'] ?? 30,
            'difficulty': questionData['difficulty'] ??
                'h1', // Sikre at spørgsmålssværhedsgrad er til stede
            'id': questionData['id'], // Inkluder spørgsmål ID til indsendelse
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

      // Start timeren for det første spørgsmål
      _startTimer();
    } catch (e) {
      _showErrorDialog('Der opstod en fejl: $e');
    }
  }

  // Start timeren for det aktuelle spørgsmål
  void _startTimer() {
    // Hent den aktuelle spørgsmåls timer
    int questionTimer = questions[currentQuestionIndex]['timer'] ?? 30;

    setState(() {
      _remainingTime = questionTimer;
    });

    // Annuller eventuel eksisterende timer
    _timer?.cancel();

    // Start en ny timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
        });
      } else {
        timer.cancel();
        _onTimeUp();
      }
    });
  }

  // Håndter hvad der sker, når tiden er op
  void _onTimeUp() {
    // Du kan vælge at automatisk gå til næste spørgsmål eller indsende quizzen
    // Her vælger vi at gå til næste spørgsmål
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tiden er op!')),
    );

    _nextQuestion();
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
    // Annuller timeren for det nuværende spørgsmål
    _timer?.cancel();

    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
      });

      // Start timeren for det næste spørgsmål
      _startTimer();
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

    // Annuller timeren, hvis den stadig kører
    _timer?.cancel();

    // Navigate to TestResults screen without passing 'userID' and 'results'
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => TestResults(
          selectedAnswers: selectedAnswers,
          questions: questions,
          quizDifficulty: quizDifficulty ?? 'h1', // Giv en standard hvis null
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
          title: const Text("Fejl"),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                if (message.contains("Ingen spørgsmål fundet") ||
                    message.contains("Token ikke fundet") ||
                    message.contains("User ID ikke fundet")) {
                  Navigator.of(context).pop(); // Forlad Test skærmen
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // Afslut timeren, når widget bliver fjernet
    _timer?.cancel();
    super.dispose();
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
        body: Center(child: Text('Ingen spørgsmål tilgængelige.')),
      );
    }

    final currentQuestion = questions[currentQuestionIndex]['question'];
    final currentAnswers =
        questions[currentQuestionIndex]['answers'] as List<String>;
    final currentTimer = questions[currentQuestionIndex]['timer'] ?? 30;

    return Scaffold(
      appBar: AppBar(
        title: Text('Spørgsmål ${currentQuestionIndex + 1}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Timer display
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.timer, color: Colors.blue),
                const SizedBox(width: 5),
                Text(
                  'Tid: $_remainingTime sek',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Spørgsmålstekst
            Text(
              currentQuestion,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Liste af svarmuligheder
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
            // Næste/Indsend knap
            ElevatedButton(
              onPressed: _nextQuestion,
              child: Text(currentQuestionIndex < questions.length - 1
                  ? 'Næste'
                  : 'Indsend'),
            ),
          ],
        ),
      ),
    );
  }
}
