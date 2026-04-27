import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../screens/ecran_home.dart';
import '../screens/quiz_play_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final String quizId;
  final String quizTitle;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int timeSpent;
  final String userId;

  const QuizResultScreen({
    super.key,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.timeSpent,
    required this.userId,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late final QuizService _quizService;
  int _totalPossiblePoints = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _loadTotalPoints();
  }

  Future<void> _loadTotalPoints() async {
    final total = await _quizService.calculateTotalPossiblePoints(widget.quizId);
    setState(() {
      _totalPossiblePoints = total;
      _isLoading = false;
    });
  }

  int get _percentage => (widget.correctAnswers / widget.totalQuestions * 100).toInt();
  int get _scorePercentage => _totalPossiblePoints > 0 
      ? (widget.score / _totalPossiblePoints * 100).toInt() 
      : 0;
  String get _formattedTime => '${(widget.timeSpent / 60).floor()}:${(widget.timeSpent % 60).toString().padLeft(2, '0')}';
  int get _xpGained => widget.score;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFFF5F7F8),
            elevation: 0,
            centerTitle: false,
            title: const Text(
              'Résultats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF071E27),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => _goToHome(context),
              ),
            ],
          ),
          
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  _buildCelebratoryHeader(),
                  const SizedBox(height: 24),
                  _buildScoreCard(),
                  const SizedBox(height: 24),
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  _buildLikeButton(context),
                  const SizedBox(height: 24),
                  _buildActionButtons(context),
                ],
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebratoryHeader() {
    String message;
    String subtitle;
    
    if (_percentage >= 80) {
      message = 'Excellent travail !';
      subtitle = 'Tu as maîtrisé ce sujet avec brio.';
    } else if (_percentage >= 60) {
      message = 'Bien joué !';
      subtitle = 'Continue comme ça, tu progresses !';
    } else {
      message = 'Bon courage !';
      subtitle = 'Réessaie pour t\'améliorer.';
    }
    
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFFFEB64C).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.emoji_events,
            size: 50,
            color: Color(0xFFFEB64C),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF071E27),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6E7980),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreCard() {
    return Container(
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
            'Score Final',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6E7980),
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${widget.score}',
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4FC3F7),
                ),
              ),
              Text(
                '/$_totalPossiblePoints',
                style: const TextStyle(
                  fontSize: 24,
                  color: Color(0xFF6E7980),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_scorePercentage}% du score maximum',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6E7980),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _scorePercentage / 100,
              backgroundColor: const Color(0xFFCFE6F2),
              color: const Color(0xFF4FC3F7),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF81C784).withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, size: 16, color: Color(0xFF81C784)),
                const SizedBox(width: 4),
                Text(
                  '+$_xpGained XP gagnés',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF286B33),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4FC3F7).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.timer, size: 20, color: Color(0xFF4FC3F7)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Temps total',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6E7980)),
                ),
                const SizedBox(height: 4),
                Text(
                  _formattedTime,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF071E27),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF81C784).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bolt, size: 20, color: Color(0xFF81C784)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Précision',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6E7980)),
                ),
                const SizedBox(height: 4),
                Text(
                  '$_percentage%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF071E27),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLikeButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quiz ajouté aux favoris !')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.favorite, color: Colors.red, size: 24),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Aimer le quiz',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => QuizPlayScreen(
                    quizId: widget.quizId,
                    quiz: {
                      'title': widget.quizTitle,
                      'questions': [],
                    },
                    userId: widget.userId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC3F7),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.replay),
                SizedBox(width: 8),
                Text('Rejouer'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton(
            onPressed: () => _goToHome(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4FC3F7), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.home, color: Color(0xFF4FC3F7)),
                SizedBox(width: 8),
                Text('Retour à l\'accueil', style: TextStyle(color: Color(0xFF4FC3F7))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _goToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          username: '',
          userId: widget.userId,
        ),
      ),
      (route) => false,
    );
  }
}