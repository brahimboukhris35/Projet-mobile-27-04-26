import 'package:bbquiz/services/quiz_service.dart';
import 'package:flutter/material.dart';
import 'bottom_nav_bar.dart';

class MainScaffold extends StatefulWidget {
  final List<Widget> screens;
  final String title;
  final String username;
  final String userId;
  final Widget? appBarActions;

  const MainScaffold({
    super.key,
    required this.screens,
    required this.username,
    required this.userId,
    this.title = 'BBQuiz',
    this.appBarActions,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  late final QuizService _quizService;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
  }

  void _setSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: widget.screens,
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavBar(
          currentIndex: _selectedIndex,
          onTap: _setSelectedIndex,
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
      decoration: const BoxDecoration(color: Colors.lightBlue),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/image/Logo.png',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Titre
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          // Actions personnalisées (notification, etc.)
          if (widget.appBarActions != null) widget.appBarActions!,
          const SizedBox(width: 12),
          // Icône déconnexion
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.logout, color: Colors.white, size: 24),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Déconnexion'),
                    content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text(
                          'Se déconnecter',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  await _quizService.signOut();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}