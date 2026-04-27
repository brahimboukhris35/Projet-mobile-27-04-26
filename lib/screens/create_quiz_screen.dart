import 'package:bbquiz/screens/ecran_home.dart';
import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../services/quiz_validation_service.dart';
import '../models/quiz_model.dart';
import '../widgets/Create_quiz/build_quiz_info_card.dart';
import '../widgets/Create_quiz/build_status_card.dart';
import '../widgets/Create_quiz/build_add_question_card.dart';
import '../widgets/Create_quiz/build_question_list_card.dart';
import '../widgets/Create_quiz/build_save_button.dart';
import '../widgets/Create_quiz/category_dropdown.dart';
import '../widgets/Create_quiz/difficulty_dropdown.dart';
import '../widgets/common/loading_overlay.dart';

class CreateQuizScreen extends StatefulWidget {
  const CreateQuizScreen({super.key, required this.userId,required this.username, this.existingQuiz});
  
  final String userId;
  final String username;
  final Map<String, dynamic>? existingQuiz;

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  late final QuizService _quizService;

  // Contrôleurs
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _questionTextController = TextEditingController();
  final List<TextEditingController> _optionControllers = List.generate(4, (_) => TextEditingController());
  final _pointsController = TextEditingController();
  // États
  String _selectedCategory = 'Culture';
  String _selectedDifficulty = 'Moyen';
  QuizStatus _selectedStatus = QuizStatus.draft;
  int _correctAnswerIndex = 0;
  int _questionPoints = 0;
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = false;
  
  // Erreurs
  String? _titleError;
  String? _descriptionError;
  String? _questionTextError;
  List<String?> _optionErrors = List.filled(4, null);
  String? _pointsError;
  
  // Catégories
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Culture', 'icon': '📚', 'color': Color(0xFF4FC3F7)},
    {'name': 'Cinéma', 'icon': '🎬', 'color': Color(0xFFE1BEE7)},
    {'name': 'Football', 'icon': '⚽', 'color': Color(0xFF81C784)},
    {'name': 'Musique', 'icon': '🎵', 'color': Color(0xFFFFB954)},
    {'name': 'Science', 'icon': '🧪', 'color': Color(0xFFFFCDD2)},
    {'name': 'Art', 'icon': '🎨', 'color': Color(0xFFB39DDB)},
    {'name': 'Histoire', 'icon': '🏛️', 'color': Color(0xFFFF8A65)},
    {'name': 'Géographie', 'icon': '🌍', 'color': Color(0xFF4FC3F7)},
    {'name': 'Technologie', 'icon': '💻', 'color': Color(0xFF81C784)},
    {'name': 'Sport', 'icon': '🏆', 'color': Color(0xFFFFB954)},
  ];
  
  final List<String> _difficulties = ['Facile', 'Moyen', 'Difficile'];

  String get _selectedIcon {
    final category = _categories.firstWhere((c) => c['name'] == _selectedCategory);
    return category['icon'];
  }
  
  Color get _selectedColor {
    final category = _categories.firstWhere((c) => c['name'] == _selectedCategory);
    return category['color'];
  }
  
  int get _totalPoints {
    return _questions.fold(0, (sum, q) => sum + (q['points'] as int));
  }

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _pointsController.text = '';
    if (widget.existingQuiz != null) _loadExistingQuiz();
  }

  void _loadExistingQuiz() {
    final quiz = widget.existingQuiz!;
    _titleController.text = quiz['title'] ?? '';
    _descriptionController.text = quiz['description'] ?? '';
    _selectedCategory = quiz['category'] ?? 'Culture';
    _selectedDifficulty = quiz['difficulty'] ?? 'Moyen';
    _questions = List<Map<String, dynamic>>.from(quiz['questions'] ?? []);
    final statusStr = quiz['status'] ?? 'draft';
    _selectedStatus = statusStr == 'private' ? QuizStatus.private : 
                      (statusStr == 'public' ? QuizStatus.public : QuizStatus.draft);
  }

  void _addQuestion() {
    final options = _optionControllers.map((c) => c.text).toList();
    
    final questionError = QuizValidationService.validateQuestionText(_questionTextController.text);
    if (questionError != null) {
      setState(() => _questionTextError = questionError);
      return;
    } else {
      setState(() => _questionTextError = null);
    }
    
    final optionsError = QuizValidationService.validateOptions(options);
    if (optionsError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(optionsError), backgroundColor: Colors.red),
      );
      return;
    }
    
    final pointsError = QuizValidationService.validatePoints(_questionPoints);
    if (pointsError != null) {
      setState(() => _pointsError = pointsError);
      return;
    } else {
      setState(() => _pointsError = null);
    }
    
    setState(() {
      _questions.add({
        'text': _questionTextController.text.trim(),
        'options': options.map((o) => o.trim()).toList(),
        'correctAnswer': _correctAnswerIndex,
        'points': _questionPoints,
      });
    });
    
    _questionTextController.clear();
    for (var c in _optionControllers) c.clear();
    _correctAnswerIndex = 0;
    //_questionPoints = 10;
    _questionTextError = null;
    _optionErrors = List.filled(4, null);
    _pointsError = null;
  }

  void _removeQuestion(int index) {
    setState(() => _questions.removeAt(index));
  }

  Future<void> _saveQuiz() async {
    final titleError = QuizValidationService.validateTitle(_titleController.text);
    if (titleError != null) {
      setState(() => _titleError = titleError);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(titleError), backgroundColor: Colors.red),
      );
      return;
    }
      // Valider les questions (minimum 1 pour tous)
    if (_questions.isEmpty) {
      const error = 'Ajoutez au moins une question';
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }
    
    // Minimum 10 questions UNIQUEMENT pour PUBLIC
    if (_selectedStatus == QuizStatus.public && _questions.length < 10) {
      final error = 'Pour publier en PUBLIC, ajoutez au moins 10 questions (${_questions.length}/10)';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    DateTime? expiresAt;
    if (_selectedStatus == QuizStatus.draft) {
      expiresAt = DateTime.now().add(const Duration(days: 7));
    }
    
 final bool isEditing = widget.existingQuiz != null;
  
  late bool success;
  String? quizId;
  
  if (isEditing) {
    // MODE ÉDITION : Mettre à jour le quiz existant
    quizId = widget.existingQuiz!['id'] ?? widget.existingQuiz!['quizId'];
    success = await _quizService.updateQuiz(
      quizId: quizId!,
      title: _titleController.text.trim(),
      description: _descriptionController.text,
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
      icon: _selectedIcon,
      questions: _questions,
      status: _selectedStatus.value,
      expiresAt: expiresAt,
    );
  } else {
    // MODE CRÉATION : Ajouter un nouveau quiz
    quizId = await _quizService.addQuiz(
      title: _titleController.text.trim(),
      description: _descriptionController.text,
      category: _selectedCategory,
      difficulty: _selectedDifficulty,
      icon: _selectedIcon,
      questions: _questions,
      status: _selectedStatus.value,
      expiresAt: expiresAt,
    );
    success = quizId != null;
  }

    setState(() => _isLoading = false);
    
    if (quizId != null) {
      String message = _selectedStatus == QuizStatus.draft ? 'Brouillon sauvegardé !' :
                       (_selectedStatus == QuizStatus.private ? 'Quiz sauvegardé en privé !' : 'Quiz publié !');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.green),
      );
      Navigator.pop(context,MaterialPageRoute(builder: (context)=> CreateQuizScreen(userId: widget.userId , username : widget.username)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la sauvegarde'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _questionTextController.dispose();
    for (var c in _optionControllers) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF006688)),
          onPressed: () => Navigator.pop(context,MaterialPageRoute(builder: (context) => HomeScreen(userId: widget.userId, username: widget.username)))
        ),
        title: const Text('Créer un quiz', style: TextStyle(color: Color(0xFF4FC3F7), fontWeight: FontWeight.bold)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                QuizInfoCard(
                  titleController: _titleController,
                  descriptionController: _descriptionController,
                  selectedCategory: _selectedCategory,
                  selectedIcon: _selectedIcon,
                  selectedColor: _selectedColor,
                  titleError: _titleError,
                  descriptionError: _descriptionError,
                  onCategoryChanged: () => setState(() {}),
                  onDifficultyChanged: () => setState(() {}),
                  categoryDropdown: CategoryDropdown(
                    selectedCategory: _selectedCategory,
                    categories: _categories,
                    onChanged: (value) => setState(() => _selectedCategory = value),
                  ),
                  difficultyDropdown: DifficultyDropdown(
                    selectedDifficulty: _selectedDifficulty,
                    difficulties: _difficulties,
                    onChanged: (value) => setState(() => _selectedDifficulty = value),
                  ),
                ),
                const SizedBox(height: 24),
                QuizStatusCard(
                  selectedStatus: _selectedStatus,
                  onStatusChanged: (status) => setState(() => _selectedStatus = status),
                ),
                const SizedBox(height: 24),
                AddQuestionCard(
                  questionController: _questionTextController,
                  optionControllers: _optionControllers,
                  correctAnswerIndex: _correctAnswerIndex,
                  questionPoints: _questionPoints,
                  questionError: _questionTextError,
                  optionErrors: _optionErrors,
                  pointsError: _pointsError,
                  onAddQuestion: _addQuestion,
                  onCorrectAnswerChanged: (value) => setState(() => _correctAnswerIndex = value),
                  onPointsChanged: (points) => setState(() => _questionPoints = points), 
                  pointsController: _pointsController,
                ),
                if (_questions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  QuestionsListCard(
                    questions: _questions,
                    totalPoints: _totalPoints,
                    onRemoveQuestion: _removeQuestion,
                  ),
                ],
                const SizedBox(height: 24),
                SaveButton(
                  status: _selectedStatus,
                  onPressed: _saveQuiz,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading) const LoadingOverlay(),
        ],
      ),
    );
  }
}