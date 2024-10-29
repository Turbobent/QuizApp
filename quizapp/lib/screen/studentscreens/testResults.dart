import 'dart:math';
import 'package:flutter/material.dart';
import 'package:quizapp/screen/studentscreens/studentHome.dart';

class TestResults extends StatefulWidget {
  final List<int?> selectedAnswers;
  final List<Map<String, dynamic>> questions;

  const TestResults({
    super.key,
    required this.selectedAnswers,
    required this.questions,
  });

  @override
  _TestResultsState createState() => _TestResultsState();
}

class _TestResultsState extends State<TestResults>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final bool _isUnderThreshold;

  @override
  void initState() {
    super.initState();

    // Calculate the score
    int score = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      if (widget.selectedAnswers[i] == widget.questions[i]['correctAnswerIndex']) {
        score++;
      }
    }

    _isUnderThreshold = (score / widget.questions.length) < 0.5;

    // Set up the animation controller
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    if (!_isUnderThreshold) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int score = 0;
    for (int i = 0; i < widget.questions.length; i++) {
      if (widget.selectedAnswers[i] == widget.questions[i]['correctAnswerIndex']) {
        score++;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Results'),
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Your Score: $score/${widget.questions.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.questions.length,
                    itemBuilder: (context, index) {
                      int? selectedAnswerIndex = widget.selectedAnswers[index];
                      bool isCorrect = selectedAnswerIndex != null &&
                          selectedAnswerIndex >= 0 &&
                          selectedAnswerIndex <
                              widget.questions[index]['answers'].length &&
                          selectedAnswerIndex ==
                              widget.questions[index]['correctAnswerIndex'];

                      return Card(
                        color: isCorrect ? Colors.green[100] : Colors.red[100],
                        child: ListTile(
                          title: Text(
                            widget.questions[index]['question'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Your Answer: ${selectedAnswerIndex != null && selectedAnswerIndex >= 0 && selectedAnswerIndex < widget.questions[index]['answers'].length ? widget.questions[index]['answers'][selectedAnswerIndex] : "No answer selected"}',
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
                        MaterialPageRoute(
                            builder: (context) => const StudentHome()),
                        (route) => false,
                      );
                    },
                    child: const Text('Home'),
                  ),
                ),
              ],
            ),
          ),
          if (_isUnderThreshold) ...[
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Stack(
                    children: List.generate(10, (index) {
                      final position = Random().nextDouble() * MediaQuery.of(context).size.width;
                      final verticalOffset = _controller.value * MediaQuery.of(context).size.height;

                      return Positioned(
                        left: position,
                        top: verticalOffset,
                        child: const Text(
                          '😭',
                          style: TextStyle(fontSize: 30),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
