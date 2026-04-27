import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuizService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== RÉCUPÉRER L'UTILISATEUR ACTUEL ====================
  
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // ==================== AJOUTER UN QUIZ ====================
  
  /// Ajoute un nouveau quiz créé par l'utilisateur connecté
  Future<String?> addQuiz({
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required String icon,
    required List<Map<String, dynamic>> questions,
    String status = 'draft',
    DateTime? expiresAt,
  }) async {
    try {
      String? userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      DocumentReference quizRef = _firestore.collection('quizzes').doc();
      
      final quizData = {
        'title': title,
        'description': description,
        'category': category,
        'difficulty': difficulty,
        'icon': icon,
        'createdBy': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'status': status,
        'plays': 0,
        'likes': 0,
        'questions': questions,
      };
      
      // Ajouter la date d'expiration pour les brouillons
      if (expiresAt != null) {
        quizData['expiresAt'] = expiresAt;
      }
      
      await quizRef.set(quizData);
      
      // Ajouter l'ID du quiz dans la liste des quizzes créés par l'utilisateur
      await _firestore
          .collection('user_quizzes')
          .doc(userId)
          .set({
            'createdQuizzes': FieldValue.arrayUnion([quizRef.id])
          }, SetOptions(merge: true));
      
      // Incrémenter le compteur de quizzes créés
      await _firestore.collection('users').doc(userId).update({
        'stats.quizzesCreated': FieldValue.increment(1),
      });
      
      return quizRef.id;
    } catch (e) {
      print('Erreur ajout quiz: $e');
      return null;
    }
  }

  // Mettre à jour un quiz existant
  Future<bool> updateQuiz({
    required String quizId,
    required String title,
    required String description,
    required String category,
    required String difficulty,
    required String icon,
    required List<Map<String, dynamic>> questions,
    required String status,
    DateTime? expiresAt,
  }) async {
    try {
      final quizData = {
        'title': title,
        'description': description,
        'category': category,
        'difficulty': difficulty,
        'icon': icon,
        'updatedAt': FieldValue.serverTimestamp(),
        'status': status,
        'questions': questions,
      };
      
      if (expiresAt != null) {
        quizData['expiresAt'] = expiresAt;
      }
      
      await _firestore.collection('quizzes').doc(quizId).update(quizData);
      return true;
    } catch (e) {
      print('Erreur mise à jour quiz: $e');
      return false;
    }
  }


  // ==================== SAUVEGARDER LE RÉSULTAT D'UN QUIZ ====================
  
  /// Sauvegarde le résultat d'une partie jouée par l'utilisateur connecté
  Future<void> saveQuizResult({
    required String quizId,
    required int score,
    required int correctAnswers,
    required int totalQuestions,
    required int timeSpent,
  }) async {
    try {
      String? userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      // Sauvegarder le résultat
      await _firestore.collection('quiz_results').add({
        'userId': userId,      
        'quizId': quizId,      
        'score': score,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'timeSpent': timeSpent,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
      // Mettre à jour les stats de l'utilisateur
      await _firestore.collection('users').doc(userId).update({
        'stats.totalScore': FieldValue.increment(score),
        'stats.quizzesPlayed': FieldValue.increment(1),
      });
      
      // Incrémenter le compteur de plays du quiz
      await _firestore.collection('quizzes').doc(quizId).update({
        'plays': FieldValue.increment(1),
      });
      
      print('Résultat sauvegardé ! Score: $score');
      
    } catch (e) {
      print('Erreur sauvegarde résultat: $e');
    }
  }

  // ==================== AJOUTER UN FAVORI ====================
  
  /// Ajoute un quiz aux favoris de l'utilisateur
  Future<void> addToFavorites(String quizId) async {
    try {
      String? userId = getCurrentUserId();
      if (userId == null) return;
      
      await _firestore
          .collection('user_favorites')
          .doc(userId)
          .set({
            'favoriteQuizzes': FieldValue.arrayUnion([quizId])
          }, SetOptions(merge: true));
          
      print('Quiz ajouté aux favoris');
    } catch (e) {
      print('Erreur: $e');
    }
  }
  
  /// Supprime un quiz des favoris
  Future<void> removeFromFavorites(String quizId) async {
    try {
      String? userId = getCurrentUserId();
      if (userId == null) return;
      
      await _firestore
          .collection('user_favorites')
          .doc(userId)
          .update({
            'favoriteQuizzes': FieldValue.arrayRemove([quizId])
          });
          
      print('Quiz retiré des favoris');
    } catch (e) {
      print('Erreur: $e');
    }
  }

  // ==================== RÉCUPÉRATION DES DONNÉES ====================
  
  /// Récupère tous les quizzes
  Stream<QuerySnapshot> getAllQuizzes() {
    return _firestore
        .collection('quizzes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  /// Récupère les quizzes créés par l'utilisateur connecté
  Stream<QuerySnapshot> getMyQuizzes() {
    String? userId = getCurrentUserId();
    if (userId == null) return const Stream.empty();
    
    return _firestore
        .collection('quizzes')
        .where('createdBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
  
  Stream<QuerySnapshot> getMyQuizzesByType(String type) {
  String? userId = getCurrentUserId();
  return FirebaseFirestore.instance
    .collection('quizzes')
    .where('createdBy', isEqualTo: userId)
    .where('status', isEqualTo: type)
    .snapshots();
  }

  // Récupérer le quiz du jour (un quiz public aléatoire)
  Stream<QuerySnapshot> getQuizOfTheDay() {
    // Récupère un quiz public aléatoire
    // Pour l'instant, on prend le premier quiz public
    return _firestore
        .collection('quizzes')
        .where('status', isEqualTo: 'public')
        .limit(1)
        .snapshots();
  }

  // Récupérer uniquement les quizzes publics
  Stream<QuerySnapshot> getPublicQuizzes() {
    return _firestore
        .collection('quizzes')
        .where('status', isEqualTo: 'public')
        .orderBy('plays', descending: true)
        .snapshots();
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Récupère l'historique des parties de l'utilisateur connecté
  Stream<QuerySnapshot> getMyQuizHistory(String userId) {
    String? userId = getCurrentUserId();
    if (userId == null) return const Stream.empty();
    
    return _firestore
        .collection('quiz_results')
        .where('userId', isEqualTo: userId)
        .orderBy('completedAt', descending: true)
        .snapshots();
  }
  
  /// Récupère les favoris de l'utilisateur connecté
  Future<List<String>> getMyFavorites() async {
    try {
      String? userId = getCurrentUserId();
      if (userId == null) return [];
      
      DocumentSnapshot doc = await _firestore
          .collection('user_favorites')
          .doc(userId)
          .get();
          
      if (doc.exists) {
        List<dynamic> favorites = doc['favoriteQuizzes'] ?? [];
        return favorites.cast<String>();
      }
      return [];
    } catch (e) {
      print('Erreur: $e');
      return [];
    }
  }
  

    // Récupérer un quiz par son ID
  Future<DocumentSnapshot> getQuizById(String quizId) async {
    return await _firestore.collection('quizzes').doc(quizId).get();
  }

  // Récupérer les quizzes recommandés (les plus joués ou récents)
  Stream<QuerySnapshot> getRecommendedQuizzes() {
    return _firestore
        .collection('quizzes')
        .where('status', isEqualTo: 'public')
        .orderBy('plays', descending: true)
        .limit(10)
        .snapshots();
  }
  // ==================== GESTION DES LIKES ====================
  Future<void> likeQuiz(String quizId) async {
    try {
      await _firestore.collection('quizzes').doc(quizId).update({
        'likes': FieldValue.increment(1),
      });
    } catch (e) {
      print('Erreur like: $e');
    }
  }

  Future<void> unlikeQuiz(String quizId) async {
    try {
      await _firestore.collection('quizzes').doc(quizId).update({
        'likes': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Erreur unlike: $e');
    }
  }

  // ==================== RECHERCHE AVANCÉE ====================

  // Rechercher des quizzes publics avec filtres
  Stream<QuerySnapshot> searchQuizzes({
    String? searchQuery,
    String? category,
    String? difficulty,
    String? sortBy, // 'plays', 'createdAt', 'likes'
  }) {
    Query query = _firestore.collection('quizzes').where('status', isEqualTo: 'public');
    
    // Filtre par catégorie
    if (category != null && category.isNotEmpty && category != 'Toutes') {
      query = query.where('category', isEqualTo: category);
    }
    
    // Filtre par difficulté
    if (difficulty != null && difficulty.isNotEmpty && difficulty != 'Toutes') {
      query = query.where('difficulty', isEqualTo: difficulty);
    }
    
    // Tri
    if (sortBy == 'plays') {
      query = query.orderBy('plays', descending: true);
    } else if (sortBy == 'createdAt') {
      query = query.orderBy('createdAt', descending: true);
    } else if (sortBy == 'likes') {
      query = query.orderBy('likes', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }
    
    return query.snapshots();
  }

  // Récupérer toutes les catégories disponibles (uniquement des quizzes publics)
  Future<List<String>> getAvailableCategories() async {
    final snapshot = await _firestore
        .collection('quizzes')
        .where('status', isEqualTo: 'public')
        .get();
    
    final categories = snapshot.docs
        .map((doc) => doc.data()['category'] as String?)  // ← String? nullable
        .where((cat) => cat != null && cat.isNotEmpty)    // ← Filtre les null
        .map((cat) => cat!)                               // ← Convertit en String non-nullable
        .toSet()
        .toList();
    
    categories.sort();
    return ['Toutes', ...categories];
  }

  // Récupérer toutes les difficultés disponibles
  Future<List<String>> getAvailableDifficulties() async {
    final snapshot = await _firestore
        .collection('quizzes')
        .where('status', isEqualTo: 'public')
        .get();
    
    final difficulties = snapshot.docs
        .map((doc) => doc.data()['difficulty'] as String?)  // ← String? nullable
        .where((diff) => diff != null && diff.isNotEmpty)   // ← Filtre les null
        .map((diff) => diff!)                               // ← Convertit en String non-nullable
        .toSet()
        .toList();
    
    difficulties.sort();
    return ['Toutes', ...difficulties];
  }
  // ==================== CALCUL DES POINTS ====================

  /// Calcule le total des points possibles pour un quiz
  Future<int> calculateTotalPossiblePoints(String quizId) async {
    try {
      // Récupérer le document du quiz
      DocumentSnapshot quizDoc = await _firestore.collection('quizzes').doc(quizId).get();
      
      if (!quizDoc.exists) {
        return 0;
      }
      
      final quizData = quizDoc.data() as Map<String, dynamic>;
      final questions = quizData['questions'] as List<dynamic>? ?? [];
      
      int total = 0;
      for (var question in questions) {
        final points = (question['points'] as num?)?.toInt() ?? 100;
        total += points;
      }
      
      return total;
    } catch (e) {
      print('Erreur calcul total points: $e');
      return 0;
    }
  }

  /// Récupère les informations d'un utilisateur
Future<Map<String, dynamic>?> getUserData(String userId) async {
  try {
    DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  } catch (e) {
    print('Erreur récupération user: $e');
    return null;
  }
}

/// Récupère les statistiques de l'utilisateur
Future<Map<String, dynamic>?> getUserStats() async {
  try {
    String? userId = getCurrentUserId();
    if (userId == null) return null;
    
    DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['stats'] as Map<String, dynamic>?;
    }
    return null;
  } catch (e) {
    print('Erreur: $e');
    return null;
  }
}

}
