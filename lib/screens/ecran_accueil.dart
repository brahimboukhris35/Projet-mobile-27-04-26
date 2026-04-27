import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/ecran_login.dart';
import '../screens/ecran_signup.dart';

class EcranAccueil extends StatelessWidget {
  const EcranAccueil({super.key});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Dialogue de confirmation comme dans ton code Java
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('BBQuiz'),
            content: const Text('Es-tu sûr de vouloir quitter le quiz ?'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text(
                  'Non',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text(
                  'Oui',
                  style: TextStyle(color: Colors.purple),
                ),
              ),
            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue,           // Bleu en haut
                Color(0xFF1A237E),    // Bleu foncé en bas
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Image du milieu (quiz en style BD)
              Expanded(
                child: Center(
                  child: Image.asset(
                    'assets/image/Logo.png',
                    width: 352,
                    height: 338,
                  ),
                ),
              ),
              
              // Bouton Commencer
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: SizedBox(
                  width: 240,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigation vers LoginActivity
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginActivity(),
                        ),
                      );
                    },
                    style: AppTheme.buttonStyle,
                    child: const Text(
                      'Connexion',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 140),
                child: SizedBox(
                  width: 240,
                  height: 65,
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigation vers SignupActivity
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupActivity(),
                        ),
                      );
                    },
                    style: AppTheme.buttonStyle,
                    child: const Text(
                      'Inscription',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

