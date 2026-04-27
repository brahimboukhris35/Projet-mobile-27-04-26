import 'package:flutter/material.dart';
import 'screens/ecran_accueil.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
    // Initialise Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const BBQuiz());
}

class BBQuiz extends StatelessWidget {
  const BBQuiz({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BBQuiz',
      home: const EcranAccueil(),
      // Dimensions iPhone
      builder: (context, child) {
        return Container(
          color: Colors.black,
          child: Center(
            child: Container(
              width: 390,
              height: 844,
              child: child,
            ),
          ),
        );
      },
    );
  }
}