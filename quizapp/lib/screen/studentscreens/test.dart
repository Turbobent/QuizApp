import 'package:flutter/material.dart';

void main() => runApp(const Test());

// Use proper class naming conventions (PascalCase)
class Test extends StatelessWidget {
  const Test({super.key});

  @override
  Widget build(BuildContext context) {

    return const Padding(
      padding: EdgeInsets.all(10),
    );
  }
}
