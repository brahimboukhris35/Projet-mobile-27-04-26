import 'package:bbquiz/screens/quiz_play_screen.dart';
import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.userId, this.initialQuery});
  
  final String userId;
  final String? initialQuery;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late final QuizService _quizService;
  
  // Contrôleurs
  final TextEditingController _searchController = TextEditingController();
  
  // Filtres
  String _selectedCategory = 'Toutes';
  String _selectedDifficulty = 'Toutes';
  String _selectedSort = 'recent';
  
  // Listes de filtres
  List<String> _categories = ['Toutes'];
  List<String> _difficulties = ['Toutes'];
  bool _isLoadingFilters = true;
  
  final List<Map<String, dynamic>> _sortOptions = [
    {'label': 'Plus récents', 'value': 'createdAt', 'icon': Icons.access_time},
    {'label': 'Plus joués', 'value': 'plays', 'icon': Icons.play_circle},
    {'label': 'Les mieux notés', 'value': 'likes', 'icon': Icons.thumb_up},
  ];

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _loadFilters();
    
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
    }
  }

  Future<void> _loadFilters() async {
    final categories = await _quizService.getAvailableCategories();
    final difficulties = await _quizService.getAvailableDifficulties();
    
    setState(() {
      _categories = categories;
      _difficulties = difficulties;
      _isLoadingFilters = false;
    });
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

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'Toutes';
      _selectedDifficulty = 'Toutes';
      _selectedSort = 'createdAt';
      _searchController.clear();
    });
  }

  String _getSortValue() {
    switch (_selectedSort) {
      case 'createdAt': return 'createdAt';
      case 'plays': return 'plays';
      case 'likes': return 'likes';
      default: return 'createdAt';
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
          'Explorer',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF071E27),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: Color(0xFF4FC3F7)),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher un quiz...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF4FC3F7)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            setState(() => _searchController.clear());
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          ),
          
          // Filtres actifs
          if (_selectedCategory != 'Toutes' || _selectedDifficulty != 'Toutes')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedCategory != 'Toutes')
                      Chip(
                        label: Text(_selectedCategory),
                        backgroundColor: const Color(0xFF4FC3F7).withOpacity(0.2),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _selectedCategory = 'Toutes'),
                      ),
                    if (_selectedDifficulty != 'Toutes')
                      Chip(
                        label: Text(_selectedDifficulty),
                        backgroundColor: const Color(0xFF4FC3F7).withOpacity(0.2),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () => setState(() => _selectedDifficulty = 'Toutes'),
                      ),
                  ],
                ),
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Résultats
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _quizService.searchQuizzes(
                searchQuery: _searchController.text.isNotEmpty ? _searchController.text : null,
                category: _selectedCategory == 'Toutes' ? null : _selectedCategory,
                difficulty: _selectedDifficulty == 'Toutes' ? null : _selectedDifficulty,
                sortBy: _getSortValue(),
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Erreur: ${snapshot.error}'),
                      ],
                    ),
                  );
                }
                
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final quizzes = snapshot.data?.docs ?? [];
                
                // Filtrage local par recherche texte
                var filteredQuizzes = quizzes.where((doc) {
                  final quiz = doc.data() as Map<String, dynamic>;
                  final title = quiz['title']?.toLowerCase() ?? '';
                  final query = _searchController.text.toLowerCase();
                  return query.isEmpty || title.contains(query);
                }).toList();
                
                if (filteredQuizzes.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 64, color: Color(0xFFBDC8D0)),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun quiz trouvé',
                          style: TextStyle(fontSize: 16, color: Color(0xFF6E7980)),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _resetFilters,
                          child: const Text('Réinitialiser les filtres'),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredQuizzes.length,
                  itemBuilder: (context, index) {
                    final doc = filteredQuizzes[index];
                    final quiz = doc.data() as Map<String, dynamic>;
                    final quizId = doc.id;
                    return _buildQuizCard(quiz, quizId);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateBottomSheet) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtres',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Catégorie
                  const Text('Catégorie', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _isLoadingFilters
                      ? const CircularProgressIndicator()
                      : Wrap(
                          spacing: 8,
                          children: _categories.map((cat) {
                            final isSelected = _selectedCategory == cat;
                            return FilterChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (selected) {
                                setStateBottomSheet(() {
                                  setState(() {
                                    _selectedCategory = selected ? cat : 'Toutes';
                                  });
                                });
                              },
                              selectedColor: const Color(0xFF4FC3F7).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF4FC3F7),
                            );
                          }).toList(),
                        ),
                  
                  const SizedBox(height: 16),
                  
                  // Difficulté
                  const Text('Difficulté', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  _isLoadingFilters
                      ? const CircularProgressIndicator()
                      : Wrap(
                          spacing: 8,
                          children: _difficulties.map((diff) {
                            final isSelected = _selectedDifficulty == diff;
                            return FilterChip(
                              label: Text(diff),
                              selected: isSelected,
                              onSelected: (selected) {
                                setStateBottomSheet(() {
                                  setState(() {
                                    _selectedDifficulty = selected ? diff : 'Toutes';
                                  });
                                });
                              },
                              selectedColor: const Color(0xFF4FC3F7).withOpacity(0.2),
                              checkmarkColor: const Color(0xFF4FC3F7),
                            );
                          }).toList(),
                        ),
                  
                  const SizedBox(height: 16),
                  
                  // Tri
                  const Text('Trier par', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sortOptions.map((option) {
                      final isSelected = _selectedSort == option['value'];
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(option['icon'], size: 16),
                            const SizedBox(width: 4),
                            Text(option['label']),
                          ],
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setStateBottomSheet(() {
                            setState(() {
                              _selectedSort = selected ? option['value'] : 'createdAt';
                            });
                          });
                        },
                        selectedColor: const Color(0xFF4FC3F7).withOpacity(0.2),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            _resetFilters();
                            setStateBottomSheet(() {});
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Réinitialiser'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4FC3F7),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Appliquer'),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz, String quizId) {
    final icon = quiz['icon'] ?? '📚';
    final title = quiz['title'] ?? 'Sans titre';
    final category = quiz['category'] ?? 'Général';
    final questionsCount = (quiz['questions'] as List?)?.length ?? 0;
    final plays = quiz['plays'] ?? 0;
    final difficulty = quiz['difficulty'] ?? 'Moyen';
    
    Color getDifficultyColor(String diff) {
      switch (diff.toLowerCase()) {
        case 'facile': return Colors.green;
        case 'moyen': return Colors.orange;
        case 'difficile': return Colors.red;
        default: return Colors.grey;
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
            color: const Color(0xFF4FC3F7).withOpacity(0.2),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: getDifficultyColor(difficulty).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    difficulty,
                    style: TextStyle(
                      fontSize: 10,
                      color: getDifficultyColor(difficulty),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  category,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF6E7980)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.play_circle_outline, size: 12, color: Color(0xFF6E7980)),
                const SizedBox(width: 2),
                Text('$plays', style: const TextStyle(fontSize: 10, color: Color(0xFF6E7980))),
                const SizedBox(width: 8),
                const Icon(Icons.quiz, size: 12, color: Color(0xFF6E7980)),
                const SizedBox(width: 2),
                Text('$questionsCount', style: const TextStyle(fontSize: 10, color: Color(0xFF6E7980))),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () {_startQuiz(quizId, quiz);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4FC3F7),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: const Text('Jouer'),
        ),
      ),
    );
  }
}