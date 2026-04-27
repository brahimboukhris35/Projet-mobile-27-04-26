import 'package:flutter/material.dart';
import '../screens/ecran_signup.dart';
import '../screens/ecran_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import '../utils/error_styles.dart'; 

class LoginActivity extends StatefulWidget {
  const LoginActivity({super.key});

  @override
  State<LoginActivity> createState() => _LoginActivityState();
}

class _LoginActivityState extends State<LoginActivity> {
  bool _isLoading = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  String _erreurMessage = '';
  // À AJOUTER - Pour gérer les erreurs visuelles (bordures rouges)
  bool _hasUsernameError = false;
  bool _hasPasswordError = false;

  Future<void> _login() async {
    setState(() {
      _erreurMessage = '';
      _hasUsernameError = false;
      _hasPasswordError = false;
    });
    String enteredText = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    
    // Un seul message pour les champs vides
    if (enteredText.isEmpty || password.isEmpty) {
      setState(() {
        _erreurMessage = 'Veuillez remplir tous les champs';
        _hasUsernameError = enteredText.isEmpty;
        _hasPasswordError = password.isEmpty;
      });
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      String email;
        // Vérifier si l'entrée est un email (contient @) ou un username
      if (enteredText.contains('@') && enteredText.contains('.')) {
        // C'est un email, l'utiliser directement
        email = enteredText;
      } else {
        // C'est un username, chercher l'email associé dans Firestore
        QuerySnapshot query = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: enteredText)
            .limit(1)
            .get();
        
        if (query.docs.isEmpty) {
          setState(() => _isLoading = false);
          setState(() => _erreurMessage = 'Username ou email invalide');
          return;
        }
        
        email = query.docs.first['email'];
      }
      // Connexion avec Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: email,
            password: _passwordController.text.trim(),
          );
      
      setState(() => _isLoading = false);
      
      if (mounted) {
        // Récupérer le username depuis Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        
        String username = userDoc['username'] ?? _usernameController.text;
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
                username: _usernameController.text.trim(),
                userId: userCredential.user!.uid, 
              ),
          ),
        );
      }
      
    } catch (e) {
      setState(() => _isLoading = false);
      
  
      if (mounted) {
        setState(() => _erreurMessage = 'Email ou mot de passe incorrect');
        setState(() => _hasUsernameError = true); 
        setState(() => _hasPasswordError = true);      
      

      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Fond général
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column( 
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card
            (
              elevation: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Titre Login
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Erreur Username
                    if (_erreurMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 20, bottom: 5),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _erreurMessage,
                            style: const TextStyle(color: Colors.red, fontSize: 14),
                          ),
                        ),
                      ),
                    
                    
                    // Champ Username
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        hintText: 'Email ou Username',
                        hintStyle: TextStyle(
                          color: _hasUsernameError ? Colors.red : Colors.grey,
                        ),
                        prefixIcon: Icon(
                          Icons.person,
                          color: _hasUsernameError ? Colors.red : Colors.lightBlue,
                        ),
                        // ✅ L'ordre est important : errorBorder doit être avant enabledBorder
                        errorBorder: ErrorStyles.errorBorder,
                        focusedErrorBorder: ErrorStyles.focusedErrorBorder,
                        border: ErrorStyles.defaultBorder,
                        enabledBorder: _hasUsernameError 
                            ? ErrorStyles.errorBorder 
                            : ErrorStyles.defaultBorder,
                        focusedBorder: _hasUsernameError 
                            ? ErrorStyles.focusedErrorBorder 
                            : ErrorStyles.focusedBorder,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Champ Password
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: _hasPasswordError ? Colors.red : Colors.grey,
                        ),
                        prefixIcon: Icon(
                          Icons.lock,
                          color: _hasPasswordError ? Colors.red : Colors.lightBlue,
                        ),
                        // ✅ L'ordre est important : errorBorder doit être avant enabledBorder
                        errorBorder: ErrorStyles.errorBorder,
                        focusedErrorBorder: ErrorStyles.focusedErrorBorder,
                        border: ErrorStyles.defaultBorder,
                        enabledBorder: _hasPasswordError 
                            ? ErrorStyles.errorBorder 
                            : ErrorStyles.defaultBorder,
                        focusedBorder: _hasPasswordError 
                            ? ErrorStyles.focusedErrorBorder 
                            : ErrorStyles.focusedBorder,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Bouton Login
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,  // ← Désactive si chargement
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: _isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text('Connexion...'),
                                ],
                              )
                            : const Text('Login', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Vous n\'avez pas de compte ? ',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignupActivity()),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'S\'inscrire',
                      style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ]
          ),
            ),
      ),
    ); 
  }
}