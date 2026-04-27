import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MultiplayerGameScreen extends StatefulWidget {
  final String gameId;
  final String userId;
  final String username;
  final String quizId;

  const MultiplayerGameScreen({
    super.key,
    required this.gameId,
    required this.userId,
    required this.username,
    required this.quizId,
  });

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  int _currentQuestionIndex = 0;
  int _selectedAnswerIndex = -1;
  bool _hasAnswered = false;
  int _timeLeft = 15;
  late List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final quizDoc = await FirebaseFirestore.instance
        .collection('quizzes')
        .doc(widget.quizId)
        .get();
    
    if (quizDoc.exists) {
      final data = quizDoc.data() as Map<String, dynamic>;
      setState(() {
        _questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
        _isLoading = false;
      });
    }
  }

  Future<void> _submitAnswer(int answerIndex) async {
    if (_hasAnswered) return;
    
    setState(() {
      _selectedAnswerIndex = answerIndex;
      _hasAnswered = true;
    });
    
    final isCorrect = answerIndex == _questions[_currentQuestionIndex]['correctAnswer'];
    final points = isCorrect ? (_questions[_currentQuestionIndex]['points'] as int? ?? 100) : 0;
    
    // Mettre à jour le score du joueur dans Firestore
    await FirebaseFirestore.instance
        .collection('multiplayer_games')
        .doc(widget.gameId)
        .update({
          'players.${widget.userId}.score': FieldValue.increment(points),
        });
    
    // Passer à la question suivante après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (_currentQuestionIndex + 1 < _questions.length) {
        setState(() {
          _currentQuestionIndex++;
          _selectedAnswerIndex = -1;
          _hasAnswered = false;
          _timeLeft = 15;
        });
      } else {
        _finishGame();
      }
    });
  }

  void _finishGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MultiplayerResultScreen(
          gameId: widget.gameId,
          userId: widget.userId,
          username: widget.username,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Aucune question disponible')),
      );
    }
    
    final currentQuestion = _questions[_currentQuestionIndex];
    final options = currentQuestion['options'] as List? ?? [];
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Question ${_currentQuestionIndex + 1}/${_questions.length}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 16, color: Color(0xFF4FC3F7)),
                const SizedBox(width: 4),
                Text(
                  '$_timeLeft',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de progression
          LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFCFE6F2),
            color: const Color(0xFF4FC3F7),
            minHeight: 4,
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Question
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Text(
                      currentQuestion['text'] ?? 'Question',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Options
                  ...List.generate(4, (index) {
                    final isSelected = _selectedAnswerIndex == index;
                    final isCorrect = index == currentQuestion['correctAnswer'];
                    final showResult = _hasAnswered;
                    
                    Color getBgColor() {
                      if (!showResult) {
                        return isSelected ? const Color(0xFFE3F2FD) : Colors.white;
                      }
                      if (isCorrect) return Colors.green.withOpacity(0.1);
                      if (isSelected && !isCorrect) return Colors.red.withOpacity(0.1);
                      return Colors.white;
                    }
                    
                    Color getBorderColor() {
                      if (!showResult) return isSelected ? const Color(0xFF4FC3F7) : Colors.grey.shade200;
                      if (isCorrect) return Colors.green;
                      if (isSelected && !isCorrect) return Colors.red;
                      return Colors.grey.shade200;
                    }
                    
                    return GestureDetector(
                      onTap: () => _submitAnswer(index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: getBgColor(),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: getBorderColor(), width: 2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: getBorderColor().withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: getBorderColor(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                options.length > index ? options[index] : 'Option ${index + 1}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            if (showResult && isCorrect)
                              const Icon(Icons.check_circle, color: Colors.green),
                            if (showResult && isSelected && !isCorrect)
                              const Icon(Icons.cancel, color: Colors.red),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          
          // Classement en direct
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('multiplayer_games')
                  .doc(widget.gameId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                
                final gameData = snapshot.data!.data() as Map<String, dynamic>;
                final players = Map<String, dynamic>.from(gameData['players'] ?? {});
                final sortedPlayers = players.entries.toList()
                  ..sort((a, b) => (b.value['score'] ?? 0).compareTo(a.value['score'] ?? 0));
                
                return Column(
                  children: [
                    const Text(
                      'Classement',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ...sortedPlayers.map((player) {
                      final isCurrent = player.key == widget.userId;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              player.value['username'],
                              style: TextStyle(
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isCurrent ? const Color(0xFF4FC3F7) : null,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${player.value['score'] ?? 0} pts',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Écran des résultats multijoueur
class MultiplayerResultScreen extends StatelessWidget {
  final String gameId;
  final String userId;
  final String username;

  const MultiplayerResultScreen({
    super.key,
    required this.gameId,
    required this.userId,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Résultats'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('multiplayer_games')
            .doc(gameId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final gameData = snapshot.data!.data() as Map<String, dynamic>;
          final players = Map<String, dynamic>.from(gameData['players'] ?? {});
          final sortedPlayers = players.entries.toList()
            ..sort((a, b) => (b.value['score'] ?? 0).compareTo(a.value['score'] ?? 0));
          
          final winner = sortedPlayers.isNotEmpty ? sortedPlayers.first : null;
          final isWinner = winner?.key == userId;
          
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: isWinner ? const Color(0xFFFFB954).withOpacity(0.2) : const Color(0xFF4FC3F7).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWinner ? Icons.emoji_events : Icons.people,
                    size: 50,
                    color: isWinner ? const Color(0xFFFFB954) : const Color(0xFF4FC3F7),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isWinner ? 'Félicitations !' : 'Bien joué !',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isWinner ? 'Vous avez gagné la partie !' : 'Terminé !',
                  style: const TextStyle(fontSize: 16, color: Color(0xFF6E7980)),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Text(
                          'Classement final',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ...sortedPlayers.asMap().entries.map((entry) {
                          final rank = entry.key + 1;
                          final player = entry.value;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: rank == 1 ? const Color(0xFFFFB954) : const Color(0xFF4FC3F7).withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$rank',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: rank == 1 ? Colors.white : const Color(0xFF4FC3F7),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  player.value['username'],
                                  style: TextStyle(
                                    fontWeight: player.key == userId ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${player.value['score'] ?? 0} pts',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC3F7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text('Retour à l\'accueil'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}