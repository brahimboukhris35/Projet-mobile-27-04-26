import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/quiz_service.dart';
import 'multiplayer_lobby.dart';

class CreateMultiplayerGame extends StatefulWidget {
  final String userId;
  final String username;

  const CreateMultiplayerGame({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<CreateMultiplayerGame> createState() => _CreateMultiplayerGameState();
}

class _CreateMultiplayerGameState extends State<CreateMultiplayerGame> {
  late final QuizService _quizService;
  String _selectedQuizId = '';
  List<Map<String, dynamic>> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    final snapshot = await _quizService.getPublicQuizzes().first;
    setState(() {
      _quizzes = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'title': data['title'] ?? 'Sans titre',
          'icon': data['icon'] ?? '📚',
          'questionsCount': (data['questions'] as List?)?.length ?? 0,
        };
      }).toList();
      _isLoading = false;
    });
  }

  String _generateGameCode() {
    final random = Random();
    final part1 = random.nextInt(9000) + 1000;
    final part2 = random.nextInt(9000) + 1000;
    final part3 = random.nextInt(9000) + 1000;
    return '$part1-$part2-$part3';
  }

  Future<void> _createGame() async {
    if (_selectedQuizId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un quiz'), backgroundColor: Colors.red),
      );
      return;
    }

    final gameCode = _generateGameCode();
    final gameId = gameCode.replaceAll('-', '');

    final gameData = {
      'gameId': gameId,
      'gameCode': gameCode,
      'createdBy': widget.userId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'waiting',
      'quizId': _selectedQuizId,
      'maxPlayers': 8,
      'players': {
        widget.userId: {
          'username': widget.username,
          'score': 0,
          'joinedAt': FieldValue.serverTimestamp(),
          'isReady': false,
        }
      },
    };

    await FirebaseFirestore.instance
        .collection('multiplayer_games')
        .doc(gameId)
        .set(gameData);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MultiplayerLobby(
            gameId: gameId,
            gameCode: gameCode,
            userId: widget.userId,
            username: widget.username,
            isHost: true,
            quizId: _selectedQuizId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Créer une partie',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF071E27),
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choisissez un quiz',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF071E27),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _quizzes.length,
                      itemBuilder: (context, index) {
                        final quiz = _quizzes[index];
                        final isSelected = _selectedQuizId == quiz['id'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedQuizId = quiz['id'];
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFE6F6FF) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF4FC3F7) : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(quiz['icon'], style: const TextStyle(fontSize: 32)),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        quiz['title'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${quiz['questionsCount']} questions',
                                        style: const TextStyle(fontSize: 12, color: Color(0xFF6E7980)),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle, color: Color(0xFF4FC3F7)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _createGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Créer la partie',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}