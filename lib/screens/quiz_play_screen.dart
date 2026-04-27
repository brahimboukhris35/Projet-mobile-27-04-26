import 'dart:async';
import 'package:bbquiz/screens/quiz_result_screen.dart';
import 'package:flutter/material.dart';
import '../services/quiz_service.dart';

class QuizPlayScreen extends StatefulWidget {
  final String quizId;
  final Map<String, dynamic> quiz;
  final String userId;

  const QuizPlayScreen({
    super.key,
    required this.quizId,
    required this.quiz,
    required this.userId,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  late final QuizService _quizService;
  
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int _selectedAnswerIndex = -1;
  bool _hasAnswered = false;
  int _score = 0;
  int _correctAnswers = 0;
  int _startTime = 0;
  
  // Timer
  int _timeLeft = 30;
  late Timer _timer;
  bool _isTimerRunning = true;
  
  // Délai après réponse
  bool _isWaiting = false;
  Timer? _waitingTimer;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _questions = List<Map<String, dynamic>>.from(widget.quiz['questions'] ?? []);
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Vérifier les conditions d'arrêt du timer
      if (!_isTimerRunning || _hasAnswered || _isWaiting || _timeLeft <= 0) {
        return;
      }
      
      setState(() {
        _timeLeft--;
        
        if (_timeLeft <= 0 && !_hasAnswered && !_isWaiting) {
          _timer.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _handleTimeout() {
    if (_hasAnswered || _isWaiting) return;
    
    setState(() {
      _hasAnswered = true;
      _isTimerRunning = false;
      _isWaiting = true;
    });
    
    // Délai de 10 secondes avant la question suivante
    _waitingTimer = Timer(const Duration(seconds: 10), () {
      _goToNextQuestion();
    });
  }

  void _selectAnswer(int index) {
    if (_hasAnswered || _isWaiting) return;
    
    // Arrêter le timer immédiatement
    _timer.cancel();
    
    final isCorrect = index == _questions[_currentQuestionIndex]['correctAnswer'];
    final int points = (_questions[_currentQuestionIndex]['points'] as num).toInt();
    
    setState(() {
      _selectedAnswerIndex = index;
      _hasAnswered = true;
      _isTimerRunning = false;
      _isWaiting = true;
      
      if (isCorrect) {
        _score += points;
        _correctAnswers++;
      }
    });
    
    // Délai de 10 secondes avant la question suivante
    _waitingTimer = Timer(const Duration(seconds: 10), () {
      _goToNextQuestion();
    });
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex + 1 < _questions.length) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerIndex = -1;
        _hasAnswered = false;
        _timeLeft = 30;
        _isTimerRunning = true;
        _isWaiting = false;
      });
      // Redémarrer le timer
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() async {
    final endTime = DateTime.now().millisecondsSinceEpoch;
    final timeSpent = (endTime - _startTime) ~/ 1000;
    
    await _quizService.saveQuizResult(
      quizId: widget.quizId,
      score: _score,
      correctAnswers: _correctAnswers,
      totalQuestions: _questions.length,
      timeSpent: timeSpent,
    );
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizResultScreen(
            quizId: widget.quizId,
            quizTitle: widget.quiz['title'] ?? 'Quiz',
            score: _score,
            totalQuestions: _questions.length,
            correctAnswers: _correctAnswers,
            timeSpent: timeSpent,
            userId: widget.userId,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _waitingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_questions.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Aucune question disponible')),
      );
    }
    
    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: Column(
        children: [
          // Top Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7F8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Close button
                GestureDetector(
                  onTap: () {
                    _timer.cancel();
                    _waitingTimer?.cancel();
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                // Progress
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4FC3F7),
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: const Color(0xFFCFE6F2),
                          color: const Color(0xFF4FC3F7),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Timer
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _timeLeft <= 10 ? Colors.red.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: _timeLeft <= 10 ? Colors.red : const Color(0xFF4FC3F7),
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$_timeLeft',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _timeLeft <= 10 ? Colors.red : const Color(0xFF006688),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Message d'attente
                  if (_isWaiting)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FC3F7).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: const Color(0xFF4FC3F7),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Question suivante dans 10 secondes...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4FC3F7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Question Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color(0xFF4FC3F7).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lightbulb,
                            size: 32,
                            color: Color(0xFF4FC3F7),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentQuestion['text'] ?? 'Question',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF071E27),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Options
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 4,
                    itemBuilder: (context, index) {
                      final options = currentQuestion['options'] as List? ?? [];
                      final isSelected = _selectedAnswerIndex == index;
                      final isCorrect = index == currentQuestion['correctAnswer'];
                      final showResult = _hasAnswered;
                      
                      Color getBackgroundColor() {
                        if (!showResult) {
                          return isSelected ? const Color(0xFFE3F2FD) : Colors.white;
                        }
                        if (isCorrect) {
                          return const Color(0xFFE8F5E9);
                        }
                        if (isSelected && !isCorrect) {
                          return const Color(0xFFFFEBEE);
                        }
                        return Colors.white;
                      }
                      
                      Color getBorderColor() {
                        if (!showResult) {
                          return isSelected ? const Color(0xFF4FC3F7) : Colors.transparent;
                        }
                        if (isCorrect) {
                          return Colors.green;
                        }
                        if (isSelected && !isCorrect) {
                          return Colors.red;
                        }
                        return Colors.transparent;
                      }
                      
                      return GestureDetector(
                        onTap: () => _selectAnswer(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: getBackgroundColor(),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: getBorderColor(), width: 2),
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
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: !showResult || !isCorrect
                                      ? const Color(0xFFCFE6F2)
                                      : (isCorrect ? Colors.green : const Color(0xFFCFE6F2)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + index),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: !showResult || !isCorrect
                                          ? const Color(0xFF006688)
                                          : Colors.white,
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
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}