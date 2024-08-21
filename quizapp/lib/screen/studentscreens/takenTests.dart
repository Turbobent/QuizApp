import 'package:flutter/material.dart';

// Model class for a taken test
class TakenTest {
  final String testName;
  final String dateTaken;
  final int score;
  final int totalQuestions;

  TakenTest({
    required this.testName,
    required this.dateTaken,
    required this.score,
    required this.totalQuestions,
  });
}

class TakenTests extends StatelessWidget {
  const TakenTests({super.key});

  @override
  Widget build(BuildContext context) {
    // Hard-coded list of taken tests
    final List<TakenTest> takenTests = [
      TakenTest(
        testName: 'Flutter Basics',
        dateTaken: '2024-08-21',
        score: 8,
        totalQuestions: 10,
      ),
      TakenTest(
        testName: 'Advanced Dart',
        dateTaken: '2024-08-18',
        score: 7,
        totalQuestions: 10,
      ),
      TakenTest(
        testName: 'State Management',
        dateTaken: '2024-08-15',
        score: 6,
        totalQuestions: 8,
      ),
      TakenTest(
        testName: 'UI/UX Design',
        dateTaken: '2024-08-10',
        score: 5,
        totalQuestions: 10,
      ),
      TakenTest(
        testName: 'Networking in Flutter',
        dateTaken: '2024-08-05',
        score: 9,
        totalQuestions: 10,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taken Tests'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView.builder(
          itemCount: takenTests.length,
          itemBuilder: (context, index) {
            final test = takenTests[index];
            return Card(
              child: ListTile(
                title: Text(
                  test.testName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                subtitle: Text('Date Taken: ${test.dateTaken}'),
                trailing: Text(
                  'Score: ${test.score}/${test.totalQuestions}',
                  style: TextStyle(
                    color: test.score >= test.totalQuestions / 2 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
