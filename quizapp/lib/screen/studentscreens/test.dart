import 'package:flutter/material.dart';

void main() => runApp(const Test());

// Use proper class naming conventions (PascalCase)
class Test extends StatelessWidget {
  const Test({super.key});

  @override
  Widget build(BuildContext context) {
    routes:
    {
      //'/test': (context) => StudentLogin(), // Define the route for student login
    }
    ;
    return Padding(
      padding: const EdgeInsets.all(10),
    );
  }
}
