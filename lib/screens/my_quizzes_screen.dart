import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_quiz_screen.dart';
import '../services/quiz_service.dart';

class MyQuizzesScreen extends StatefulWidget {
  const MyQuizzesScreen({super.key, required this.userId, required this.username});
  
  final String userId;
  final String username;

  @override
  State<MyQuizzesScreen> createState() => _MyQuizzesScreenState();
}

class _MyQuizzesScreenState extends State<MyQuizzesScreen> with SingleTickerProviderStateMixin {
  late final QuizService _quizService;
  late TabController _tabController;
  
  // Search controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _tabController = TabController(length: 3, vsync: this);//nombre d'onglets 3 public brouilon et private
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3FAFF),
      body: Column(
        children: [
          // Header personnalisé 
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(
              top: 48,  
              left: 16,
              right: 16,
              bottom: 8,
            ),
            child: Column(
              children: [
                // Bouton Nouveau Quiz
                SizedBox(
                  width: 300,  
                  height: 150,  // Hauteur fixe
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                      MaterialPageRoute(
                          builder: (context) => CreateQuizScreen(userId: widget.userId,username: widget.username,),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add_circle, size: 24),
                    label: const Text(
                      'Nouveau Quiz',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC3F7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Tabs
                TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFF006688),
                  labelColor: const Color(0xFF006688),
                  unselectedLabelColor: const Color(0xFF6E7980),
                  tabs: const [
                    Tab(text: 'Privés'),
                    Tab(text: 'Publiés'),
                    Tab(text: 'Brouillons'),
                  ],
                ),
              ],
            ),
          ),
          
          // Contenu principal
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildQuizzesList(type: 'private'),     // Privés
                _buildQuizzesList(type: 'public'),      // Publiés
                _buildQuizzesList(type: 'draft'), 
              ],
            ),
          ),
        ],
      ),
    );
  }
    
    
  Widget _buildQuizzesList({required String type}) {
    return StreamBuilder<QuerySnapshot>(
      stream: _quizService.getMyQuizzesByType(type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(''));
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allQuizzes = snapshot.data?.docs ?? [];
        
        var quizzes = allQuizzes.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data['title'] ?? '').toString().toLowerCase();
          return title.contains(_searchQuery.toLowerCase());
        }).toList();
        String emptyMessage;
        IconData emptyIcon;
        String buttonText;
        switch (type) {
          case 'public':
            emptyMessage = 'Aucun quiz publié';
            emptyIcon = Icons.public;
            buttonText = 'Créer un quiz';
            break;
          case 'private':
            emptyMessage = 'Aucun quiz privé';
            emptyIcon = Icons.lock;
            buttonText = 'Créer un quiz privé';
            break;
          case 'draft':
            emptyMessage = 'Aucun brouillon';
            emptyIcon = Icons.edit_note;
            buttonText = 'Créer un brouillon';
            break;
          default:
            emptyMessage = 'Aucun quiz';
            emptyIcon = Icons.quiz_outlined;
            buttonText = 'Créer un quiz';
        }
        if (quizzes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  emptyIcon,
                  size: 64,
                  color: const Color(0xFFBDC8D0),
                ),
                const SizedBox(height: 16),
                Text(
                  emptyMessage,
                  style: const TextStyle(fontSize: 16, color: Color(0xFF6E7980)),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateQuizScreen(userId: widget.userId,username: widget.username,),
                      ),
                    );
                  },
                  child: Text(buttonText),
                ),
              ],
            ),
          );
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            shrinkWrap: true, 
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 1,
              childAspectRatio: 1.3,
              mainAxisSpacing: 16,
            ),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final doc = quizzes[index];
              final quiz = doc.data() as Map<String, dynamic>;
              final quizId = doc.id;
              final questionsCount = (quiz['questions'] as List?)?.length ?? 0;
              
              if (type == 'public') {
                return _buildPublishedQuizCard(quiz, quizId, questionsCount);
              } else if (type == 'private') {
                return _buildPrivateQuizCard(quiz, quizId, questionsCount);
              } else {
                return _buildDraftQuizCard(quiz, quizId, questionsCount);
              }
            },
          ),
        );
      },
    );
  }
  
  Widget _buildPublishedQuizCard(Map<String, dynamic> quiz, String quizId, int questionsCount) {
    final icon = quiz['icon'] ?? '📚';
    final category = quiz['category'] ?? 'Général';
    final plays = quiz['plays'] ?? 0;  
    final likes = quiz['likes'] ?? 0; 
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, 
        children: [
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF4FC3F7).withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(icon, style: const TextStyle(fontSize: 48)),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF006688)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    quiz['title'] ?? 'Sans titre',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStat(Icons.play_circle, '$plays'),
                      const SizedBox(width: 16),
                      _buildStat(Icons.thumb_up, '$likes'),
                      const SizedBox(width: 16),
                      _buildStat(Icons.leaderboard, '${quiz['avgScore'] ?? 0}%'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${questionsCount} questions',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6E7980)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Color(0xFF006688)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateQuizScreen(
                              userId: widget.userId,
                              existingQuiz: {'id': quizId, ...quiz},
                              username: widget.username ,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDraftQuizCard(Map<String, dynamic> quiz, String quizId, int questionsCount) {
    final questionsTotal = (quiz['questions'] as List?)?.length ?? 0;
    final progress = questionsTotal > 0 ? (questionsCount / questionsTotal) : 0.0;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFBDC8D0), width: 1),
      ),
      color: Colors.white.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quiz['title'] ?? 'Sans titre',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${questionsCount} questions créées',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6E7980)),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFBDC8D0),
              color: const Color(0xFF4FC3F7),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 4),
            Text(
              '${(progress * 100).toInt()}% complété',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF006688)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateQuizScreen(
                        userId: widget.userId,
                        existingQuiz: {'id': quizId, ...quiz},
                        username: widget.username,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF006688),
                  side: const BorderSide(color: Color(0xFF4FC3F7), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Reprendre'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPrivateQuizCard(Map<String, dynamic> quiz, String quizId, int questionsCount) {
    final icon = quiz['icon'] ?? '🔒';
    final category = quiz['category'] ?? 'Général';
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, 
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(icon, style: const TextStyle(fontSize: 48)),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock, size: 10, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          category,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    quiz['title'] ?? 'Sans titre',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, size: 12, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          'Privé',
                          style: TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${questionsCount} questions',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6E7980)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20, color: Color(0xFF006688)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateQuizScreen(
                              userId: widget.userId,
                              existingQuiz: {'id': quizId, ...quiz},
                              username: widget.username,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6E7980)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}