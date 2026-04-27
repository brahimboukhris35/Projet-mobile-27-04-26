import 'package:bbquiz/screens/multiplayer/multiplayer_game_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class MultiplayerLobby extends StatefulWidget {
  final String gameId;
  final String gameCode;
  final String userId;
  final String username;
  final bool isHost;
  final String quizId;

  const MultiplayerLobby({
    super.key,
    required this.gameId,
    required this.gameCode,
    required this.userId,
    required this.username,
    required this.isHost,
    required this.quizId,
  });

  @override
  State<MultiplayerLobby> createState() => _MultiplayerLobbyState();
}

class _MultiplayerLobbyState extends State<MultiplayerLobby> {
  bool _isStarting = false;

  Future<void> _startGame() async {
    if (!widget.isHost) return;
    
    setState(() => _isStarting = true);
    
    await FirebaseFirestore.instance
        .collection('multiplayer_games')
        .doc(widget.gameId)
        .update({
          'status': 'playing',
          'startedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.gameCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Code copié !'), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Salle d\'attente',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF071E27),
          ),
        ),
        centerTitle: false,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('multiplayer_games')
            .doc(widget.gameId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final gameData = snapshot.data!.data() as Map<String, dynamic>;
          final gameStatus = gameData['status'] as String? ?? 'waiting';
          
          // ✅ REDIRECTION AUTOMATIQUE pour tous les joueurs
          if (gameStatus == 'playing' && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MultiplayerGameScreen(
                    gameId: widget.gameId,
                    userId: widget.userId,
                    username: widget.username,
                    quizId: widget.quizId,
                  ),
                ),
              );
            });
            return const Center(child: CircularProgressIndicator());
          }

          final players = Map<String, dynamic>.from(gameData['players'] ?? {});
          final playersList = players.entries.toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Code de la partie
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF4FC3F7), width: 2),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.code, color: Color(0xFF4FC3F7)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.gameCode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Color(0xFF4FC3F7)),
                        onPressed: _copyCode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Liste des joueurs
                Expanded(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people, color: Color(0xFF4FC3F7)),
                              const SizedBox(width: 8),
                              Text(
                                'Joueurs (${playersList.length}/8)',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Expanded(
                            child: ListView.builder(
                              itemCount: playersList.length,
                              itemBuilder: (context, index) {
                                final player = playersList[index];
                                final isCurrentUser = player.key == widget.userId;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF4FC3F7).withOpacity(0.2),
                                    child: Text(
                                      player.value['username'][0].toUpperCase(),
                                      style: const TextStyle(color: Color(0xFF4FC3F7)),
                                    ),
                                  ),
                                  title: Text(
                                    player.value['username'],
                                    style: TextStyle(
                                      fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                    ),
                                  ),
                                  trailing: isCurrentUser
                                      ? const Chip(
                                          label: Text('Vous'),
                                          backgroundColor: Color(0xFFE6F6FF),
                                        )
                                      : (player.key == gameData['createdBy']
                                          ? const Chip(
                                              label: Text('Hôte'),
                                              backgroundColor: Color(0xFFFFB954),
                                            )
                                          : null),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Bouton démarrer (hôte seulement)
                if (widget.isHost)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: playersList.length >= 2 && !_isStarting
                          ? _startGame
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isStarting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white),
                            )
                          : const Text(
                              'Démarrer la partie',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
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