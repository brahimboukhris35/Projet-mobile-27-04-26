import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'multiplayer_lobby.dart';

class JoinMultiplayerGame extends StatefulWidget {
  final String userId;
  final String username;

  const JoinMultiplayerGame({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<JoinMultiplayerGame> createState() => _JoinMultiplayerGameState();
}

class _JoinMultiplayerGameState extends State<JoinMultiplayerGame> {
  final List<TextEditingController> _codeControllers = List.generate(3, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(3, (_) => FocusNode());
  bool _isJoining = false;

  String get _fullCode => _codeControllers.map((c) => c.text).join('-');

  void _onCodeChanged(int index, String value) {
    if (value.length == 4 && index < 2) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  Future<void> _joinGame() async {
    if (_fullCode.length != 14) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code invalide'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isJoining = true);

    final gameId = _fullCode.replaceAll('-', '');
    final gameDoc = await FirebaseFirestore.instance
        .collection('multiplayer_games')
        .doc(gameId)
        .get();

    if (!gameDoc.exists) {
      setState(() => _isJoining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partie introuvable'), backgroundColor: Colors.red),
      );
      return;
    }

    final gameData = gameDoc.data()!;
    
    if (gameData['status'] != 'waiting') {
      setState(() => _isJoining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La partie a déjà commencé'), backgroundColor: Colors.red),
      );
      return;
    }

    final players = Map<String, dynamic>.from(gameData['players'] ?? {});
    
    if (players.length >= gameData['maxPlayers']) {
      setState(() => _isJoining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La partie est pleine'), backgroundColor: Colors.red),
      );
      return;
    }

    if (players.containsKey(widget.userId)) {
      setState(() => _isJoining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vous êtes déjà dans cette partie'), backgroundColor: Colors.red),
      );
      return;
    }

    players[widget.userId] = {
      'username': widget.username,
      'score': 0,
      'joinedAt': FieldValue.serverTimestamp(),
      'isReady': false,
    };

    await FirebaseFirestore.instance
        .collection('multiplayer_games')
        .doc(gameId)
        .update({'players': players});

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MultiplayerLobby(
            gameId: gameId,
            gameCode: _fullCode,
            userId: widget.userId,
            username: widget.username,
            isHost: false,
            quizId: gameData['quizId'],
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
          'Rejoindre une partie',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF071E27),
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Code de la partie',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6E7980),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      return Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _codeControllers[index],
                              focusNode: _focusNodes[index],
                              textAlign: TextAlign.center,
                              maxLength: 4,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                counterText: '',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onChanged: (value) => _onCodeChanged(index, value),
                            ),
                          ),
                          if (index < 2) const SizedBox(width: 12),
                          if (index < 2) const Text('-', style: TextStyle(fontSize: 20)),
                          if (index < 2) const SizedBox(width: 12),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isJoining ? null : _joinGame,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isJoining
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : const Text(
                              'Rejoindre',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}