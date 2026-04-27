import 'package:bbquiz/screens/multiplayer/multiplayer_home.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/common/main_scaffold.dart';
import '../services/quiz_service.dart';
import '../screens/my_quizzes_screen.dart';
import '../screens/create_quiz_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/quiz_play_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.username, required this.userId});
  
  final String username;
  final String userId;

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      username: username,
      userId: userId,
      title: 'MyQuiz',
      appBarActions: _buildAppBarActions(context),
      screens: [
        HomeBody(username: username, userId: userId),
        MyQuizzesScreen(userId: userId, username: username),
        CreateQuizScreen(userId: userId, username: username),
        ProfileScreen(userId: userId, username: username),
      ],
    );
  }

  Widget _buildAppBarActions(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications - À venir')),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ==================== HOME BODY ====================

class HomeBody extends StatefulWidget {
  final String username;
  final String userId;

  const HomeBody({
    super.key,
    required this.username,
    required this.userId,
  });

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  late final QuizService _quizService;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
  }

  void _searchQuizzes(String query) {
    if (query.trim().isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExploreScreen(
            userId: widget.userId,
            initialQuery: query.trim(),
          ),
        ),
      );
    }
  }

  void _startQuiz(String quizId, Map<String, dynamic> quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPlayScreen(
          quizId: quizId,
          quiz: quiz,
          userId: widget.userId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [       
          // Welcome Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bonjour, ${widget.username} !',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF071E27),
                  letterSpacing: -0.01,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Prêt pour ton défi quotidien ?',
                style: TextStyle(fontSize: 16, color: Color(0xFF6E7980)),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Barre de recherche
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un quiz...',
                prefixIcon: const Icon(Icons.search, color: Colors.lightBlue),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onSubmitted: _searchQuizzes,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quiz du jour
          StreamBuilder<QuerySnapshot>(
            stream: _quizService.getQuizOfTheDay(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey[200],
                  ),
                  child: const Center(child: CircularProgressIndicator()),
                );
              }
              
              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }
              
              final quizDoc = snapshot.data!.docs.first;
              final quiz = quizDoc.data() as Map<String, dynamic>;
              final quizId = quizDoc.id;
              
              return _buildQuizOfTheDay(quiz, quizId);
            },
          ),
          

          const SizedBox(height: 16),
        
          // BOUTON MULTIJOUEUR (placé APRÈS le Quiz du jour)
          _buildMultiplayerButton(),
        
        const SizedBox(height: 24),
          
          // Section Quiz recommandés
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recommandés pour vous',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  // Changer l'index via le contexte (optionnel)
                  // Pour l'instant, on garde le comportement actuel
                },
                child: const Text('Voir plus', style: TextStyle(color: Colors.lightBlue)),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Liste des quiz recommandés
          StreamBuilder<QuerySnapshot>(
            stream: _quizService.getRecommendedQuizzes(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final quizzes = snapshot.data?.docs ?? [];
              
              if (quizzes.isEmpty) {
                return const Center(child: Text('Aucun quiz disponible'));
              }
              
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quizzes.length > 3 ? 3 : quizzes.length,
                itemBuilder: (context, index) {
                  final quizDoc = quizzes[index];
                  final quiz = quizDoc.data() as Map<String, dynamic>;
                  final quizId = quizDoc.id;
                  return _buildQuizCard(quiz, quizId);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz, String quizId) {
    final icon = quiz['icon'] ?? '📚';
    final title = quiz['title'] ?? 'Sans titre';
    final category = quiz['category'] ?? 'Général';
    final questionsCount = (quiz['questions'] as List?)?.length ?? 0;
    final plays = quiz['plays'] ?? 0;
    
    Color getColor(String colorName) {
      switch (colorName) {
        case 'blue': return Colors.blue;
        case 'purple': return Colors.purple;
        case 'green': return Colors.green;
        case 'orange': return Colors.orange;
        case 'red': return Colors.red;
        default: return Colors.lightBlue;
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: getColor(quiz['color'] ?? 'blue').withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 28)),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            Text(
              '$questionsCount questions',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6E7980)),
            ),
            const SizedBox(width: 8),
            Row(
              children: [
                const Icon(Icons.play_circle_outline, size: 12, color: Color(0xFF6E7980)),
                const SizedBox(width: 2),
                Text('$plays', style: const TextStyle(fontSize: 12, color: Color(0xFF6E7980))),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () => _startQuiz(quizId, quiz),
          style: ElevatedButton.styleFrom(
            backgroundColor: getColor(quiz['color'] ?? 'blue'),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('Jouer'),
        ),
      ),
    );
  }

  Widget _buildQuizOfTheDay(Map<String, dynamic> quiz, String quizId) {
    final icon = quiz['icon'] ?? '📚';
    final title = quiz['title'] ?? 'Quiz du jour';
    final category = quiz['category'] ?? 'Général';
    final questionsCount = (quiz['questions'] as List?)?.length ?? 0;
    
    return GestureDetector(
      onTap: () => _startQuiz(quizId, quiz),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4FC3F7), Color(0xFF006688)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4FC3F7).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'QUIZ DU JOUR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$category • $questionsCount questions',
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _startQuiz(quizId, quiz),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF006688),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                      child: const Text('Jouer'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 40)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  

  Widget _buildMultiplayerButton() {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MultiplayerHome(
            userId: widget.userId,
            username: widget.username,
          ),
        ),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9C27B0), Color(0xFFE91E63)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9C27B0).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.people,
                size: 32,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'JOUER AVEC LA COMMUNAUTÉ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Défiez vos amis en multijoueur !',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '🔥 En ligne',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '👥 2-8 joueurs',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Color(0xFFE91E63),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}