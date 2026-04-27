import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/quiz_service.dart';
import '../screens/ecran_login.dart';


class ProfileScreen extends StatefulWidget {
  final String userId;
  final String username;

  const ProfileScreen({
    super.key,
    required this.userId,
    required this.username,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final QuizService _quizService;
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _quizService = QuizService();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final stats = await _quizService.getUserStats();
    final userData = await _quizService.getUserData(widget.userId);
    
    setState(() {
      _userStats = stats;
      _userData = userData;
      _isLoading = false;
    });
  }

  int get _totalXP => _userStats?['totalScore'] ?? 0;
  int get _quizzesPlayed => _userStats?['quizzesPlayed'] ?? 0;
  int get _quizzesCreated => _userStats?['quizzesCreated'] ?? 0;
  
  String get _joinDate {
    final createdAt = _userData?['createdAt'] as Timestamp?;
    if (createdAt != null) {
      final date = createdAt.toDate();
      return 'Membre depuis ${_getMonthName(date.month)} ${date.year}';
    }
    return 'Membre récent';
  }

  String _getMonthName(int month) {
    const months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 
                    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const SizedBox(), 
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF071E27),
          ),
        ),
        centerTitle: false,
        actions: [
          Text(
            'BBQuiz',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4FC3F7),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  
                  // Stats Grid
                  _buildStatsGrid(),
                  const SizedBox(height: 24),
                  
                  // Achievement Badges
                  _buildBadgesSection(),
                  const SizedBox(height: 24),
                  
                  // Menu Items
                  _buildMenuItems(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4FC3F7),
                      width: 3,
                    ),
                    color: const Color(0xFF4FC3F7).withOpacity(0.2),
                  ),
                  child: Center(
                    child: Text(
                      widget.username.isNotEmpty ? widget.username[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4FC3F7),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FC3F7),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Name
            Text(
              widget.username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF071E27),
              ),
            ),
            const SizedBox(height: 4),
            
            // Join date
            Text(
              _joinDate,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6E7980),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        _buildStatCard(
          icon: Icons.bolt,
          label: 'XP Totale',
          value: '$_totalXP',
          color: const Color(0xFF4FC3F7),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.task_alt,
          label: 'Quiz Finis',
          value: '$_quizzesPlayed',
          color: const Color(0xFF4FC3F7),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.add_circle,
          label: 'Quiz Créés',
          value: '$_quizzesCreated',
          color: const Color(0xFF4FC3F7),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF6E7980),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection() {
    final badges = [
      {'icon': Icons.military_tech, 'name': 'Expert', 'color': const Color(0xFFFEB64C), 'locked': false},
      {'icon': Icons.local_fire_department, 'name': 'Série 7j', 'color': const Color(0xFF81C784), 'locked': false},
      {'icon': Icons.workspace_premium, 'name': 'Major', 'color': const Color(0xFF4FC3F7), 'locked': false},
      {'icon': Icons.emoji_events, 'name': 'Champion', 'color': Colors.grey, 'locked': true},
    ];

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Badges récents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF071E27),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(color: Color(0xFF4FC3F7)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: badges.map((badge) {
                final isLocked = badge['locked'] as bool;
                return Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: isLocked 
                            ? Colors.grey.withOpacity(0.2)
                            : (badge['color'] as Color).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        badge['icon'] as IconData,
                        size: 30,
                        color: isLocked ? Colors.grey : badge['color'] as Color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      badge['name'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isLocked ? Color(0xFFBDC8D0) : Color(0xFF6E7980),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems() {
    return Container(
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
          _buildMenuItem(
            icon: Icons.edit,
            label: 'Modifier le profil',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.workspace_premium,
            label: 'Mes succès',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.notifications,
            label: 'Notifications',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.help,
            label: 'Aide & Support',
            onTap: () {},
          ),
          _buildMenuItem(
            icon: Icons.logout,
            label: 'Déconnexion',
            isLogout: true,
            onTap: () async {
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
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginActivity()),
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              color: isLogout ? Colors.red : const Color(0xFF4FC3F7),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  color: isLogout ? Colors.red : const Color(0xFF071E27),
                  fontWeight: isLogout ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isLogout ? Colors.red.withOpacity(0.5) : const Color(0xFF6E7980),
            ),
          ],
        ),
      ),
    );
  }
}