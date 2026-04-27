import 'package:flutter/material.dart';
import '../screens/ecran_login.dart';
import '../screens/ecran_home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../utils/error_styles.dart'; 


class SignupActivity extends StatefulWidget {
  const SignupActivity({super.key});

  @override
  State<SignupActivity> createState() => _SignupActivityState();
}

class _SignupActivityState extends State<SignupActivity> {
  final UserService _userService = UserService(); 
  bool _isLoading = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _firstnameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Message d'erreur
  String _erreurMessage = '';
  
  // Pour gérer les bordures rouges
  bool _hasNameError = false;
  bool _hasFirstnameError = false;
  bool _hasEmailError = false;
  bool _hasUsernameError = false;
  bool _hasPasswordError = false;

  Future<void> _signUp() async {
    setState(() {
      _erreurMessage = '';
      _hasNameError = false;
      _hasFirstnameError = false;
      _hasEmailError = false;
      _hasUsernameError = false;
      _hasPasswordError = false;
    });

    String name = _nameController.text.trim();
    String firstname = _firstnameController.text.trim();
    String email = _emailController.text.trim();
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    bool hasError = false;
    
    // Validation des champs
    // Vérification globale des champs vides
    if (name.isEmpty || firstname.isEmpty || email.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() {
        _erreurMessage = 'Veuillez remplir tous les champs';
        _hasNameError = name.isEmpty;
        _hasFirstnameError = firstname.isEmpty;
        _hasEmailError = email.isEmpty;
        _hasUsernameError = username.isEmpty;
        _hasPasswordError = password.isEmpty;
      });
      return;
    }

// Vérification email valide
if (!email.contains('@')) {
  setState(() {
    _erreurMessage = 'Email invalide';
    _hasEmailError = true;
  });
  return;
}

// Vérification mot de passe trop court
if (password.length < 6) {
  setState(() {
    _erreurMessage = 'Mot de passe trop court (min 6 caractères)';
    _hasPasswordError = true;
  });
  return;
}
    
    setState(() => _isLoading = true);
    
    try {

    // VÉRIFIER SI USERNAME EXISTE DÉJÀ
      QuerySnapshot existingUser = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: _usernameController.text.trim())
          .limit(1)
          .get();
      
      if (existingUser.docs.isNotEmpty) {
        setState(() => _isLoading = false);
        setState(() => _erreurMessage = 'Ce username est déjà pris');
        setState(() => _hasUsernameError = true);
        return;
      }

      // 1. Créer l'utilisateur dans Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      
      // 2. Stocker les infos dans Firestore AVEC LE SERVICE
      await _userService.createUserProfile(
        userId: userCredential.user!.uid,
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        name: _nameController.text.trim(),
        firstname: _firstnameController.text.trim(),
      );
          
      setState(() => _isLoading = false);
      
      if (mounted) {
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
      
      String message = 'Erreur lors de l\'inscription';
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          setState(() => _erreurMessage = 'Cet email est déjà utilisé');
          setState(() => _hasEmailError = true);
        } else if (e.code == 'weak-password') {
          setState(() => _erreurMessage = 'Mot de passe trop faible');
          setState(() => _hasPasswordError = true);
        }
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column( 
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 20,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Titre Sign Up
                        const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.lightBlue,
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Erreur Name
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
                        
                        // Champ Name
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Name',
                            hintStyle: TextStyle(
                              color: _hasNameError ? Colors.red : Colors.grey,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: _hasNameError ? Colors.red : Colors.lightBlue,
                            ),
                            errorBorder: ErrorStyles.errorBorder,
                            focusedErrorBorder: ErrorStyles.focusedErrorBorder,
                            border: ErrorStyles.defaultBorder,
                            enabledBorder: _hasNameError 
                                ? ErrorStyles.errorBorder 
                                : ErrorStyles.defaultBorder,
                            focusedBorder: _hasNameError 
                                ? ErrorStyles.focusedErrorBorder 
                                : ErrorStyles.focusedBorder,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                          ),
                        ),
                          
                        const SizedBox(height: 15),
                        // Champ First Name
                        TextField(
                          controller: _firstnameController,
                          decoration: InputDecoration(
                            hintText: 'First Name',
                            hintStyle: TextStyle(
                              color: _hasFirstnameError ? Colors.red : Colors.grey,
                            ),
                            prefixIcon: Icon(
                              Icons.person_outline,
                              color: _hasFirstnameError ? Colors.red : Colors.lightBlue,
                            ),
                            errorBorder: ErrorStyles.errorBorder,
                            focusedErrorBorder: ErrorStyles.focusedErrorBorder,
                            border: ErrorStyles.defaultBorder,
                            enabledBorder: _hasFirstnameError 
                                ? ErrorStyles.errorBorder 
                                : ErrorStyles.defaultBorder,
                            focusedBorder: _hasFirstnameError 
                                ? ErrorStyles.focusedErrorBorder 
                                : ErrorStyles.focusedBorder,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        // Champ Email
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            hintText: 'Email',
                            hintStyle: TextStyle(
                              color: _hasEmailError ? Colors.red : Colors.grey,
                            ),
                            prefixIcon: Icon(
                              Icons.email,
                              color: _hasEmailError ? Colors.red : Colors.lightBlue,
                            ),
                            errorBorder: ErrorStyles.errorBorder,
                            focusedErrorBorder: ErrorStyles.focusedErrorBorder,
                            border: ErrorStyles.defaultBorder,
                            enabledBorder: _hasEmailError 
                                ? ErrorStyles.errorBorder 
                                : ErrorStyles.defaultBorder,
                            focusedBorder: _hasEmailError 
                                ? ErrorStyles.focusedErrorBorder 
                                : ErrorStyles.focusedBorder,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                          ),
                        ),
                        
                        const SizedBox(height: 15),
                        // Champ Username
                        TextField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            hintText: 'Username',
                            hintStyle: TextStyle(
                              color: _hasUsernameError ? Colors.red : Colors.grey,
                            ),
                            prefixIcon: Icon(
                              Icons.account_circle,
                              color: _hasUsernameError ? Colors.red : Colors.lightBlue,
                            ),
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
                        
                        const SizedBox(height: 15),
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
                        
                        // Bouton Sign Up
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _signUp,
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
                                      Text('Inscription...'),
                                    ],
                                  )
                                : const Text('Sign Up', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Texte avec 50px en dessous du Card
              Padding(
                padding: EdgeInsets.only(top: 30),  // ← Marge en HAUT (50px sous le Card)
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Déjà un compte ? ',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(context,MaterialPageRoute(builder: (context) => const LoginActivity()),);
                      },
                      style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}