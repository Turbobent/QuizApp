import 'package:flutter/material.dart';
import 'package:quizapp/screen/studentscreens/studentHome.dart';

class TestResults extends StatelessWidget {
  final List<int?> selectedAnswers;
  final List<Map<String, dynamic>> questions;

  const TestResults({
    super.key,
    required this.selectedAnswers,
    required this.questions,
  });

  @override
  Widget build(BuildContext context) {
    int score = 0;

    // Calculate the score
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i]['correctAnswerIndex']) {
        score++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Your Score: $score/${questions.length}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  bool isCorrect = selectedAnswers[index] ==
                      questions[index]['correctAnswerIndex'];
                  return Card(
                    color: isCorrect ? Colors.green[100] : Colors.red[100],
                    child: ListTile(
                      title: Text(
                        questions[index]['question'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Your Answer: ${selectedAnswers[index] != null ? questions[index]['answers'][selectedAnswers[index]!] : "No answer selected"}',
                        style: TextStyle(
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const StudentHome()),
                    (route) => false,
                  );
                },
                child: const Text('Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
