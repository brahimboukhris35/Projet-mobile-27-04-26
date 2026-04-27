import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== RÉCUPÉRER L'UTILISATEUR ACTUEL ====================
  
  /// Récupère l'ID de l'utilisateur connecté
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Récupère l'utilisateur connecté
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // ==================== CRÉATION / LECTURE / MISE À JOUR ====================
  
  /// Crée un profil utilisateur dans Firestore (appelé après inscription)
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String username,
    required String name,
    required String firstname,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'email': email,
        'username': username,
        'name': name,
        'firstname': firstname,
        'createdAt': FieldValue.serverTimestamp(),
        'stats': {
          'totalScore': 0,
          'quizzesPlayed': 0,
          'quizzesCreated': 0,
        }
      });
      print('Profil utilisateur créé avec succès');
    } catch (e) {
      print('Erreur création profil: $e');
      throw e;
    }
  }

  /// Récupère les données d'un utilisateur par son ID
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erreur récupération utilisateur: $e');
      return null;
    }
  }

  /// Récupère les données de l'utilisateur connecté
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    String? userId = getCurrentUserId();
    if (userId == null) return null;
    return getUserData(userId);
  }

  /// Récupère un utilisateur par son username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return query.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erreur recherche username: $e');
      return null;
    }
  }

  /// Récupère un utilisateur par son email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        return query.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erreur recherche email: $e');
      return null;
    }
  }

  // ==================== STATISTIQUES UTILISATEUR ====================
  
  /// Met à jour le score total de l'utilisateur
  Future<void> updateUserScore(int points) async {
    try {
      String? userId = getCurrentUserId();
      if (userId == null) return;
      
      await _firestore.collection('users').doc(userId).update({
        'stats.totalScore': FieldValue.increment(points),
        'stats.quizzesPlayed': FieldValue.increment(1),
      });
      print('Score mis à jour: +$points points');
    } catch (e) {
      print('Erreur mise à jour score: $e');
    }
  }

  /// Incrémente le nombre de quizzes créés par l'utilisateur
  Future<void> incrementQuizzesCreated() async {
    try {
      String? userId = getCurrentUserId();
      if (userId == null) return;
      
      await _firestore.collection('users').doc(userId).update({
        'stats.quizzesCreated': FieldValue.increment(1),
      });
      print('Nombre de quizzes créés incrémenté');
    } catch (e) {
      print('Erreur: $e');
    }
  }

  /// Récupère les statistiques de l'utilisateur connecté
  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      String? userId = getCurrentUserId();
      if (userId == null) return null;
      
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['stats'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Erreur récupération stats: $e');
      return null;
    }
  }

  // ==================== MISE À JOUR DU PROFIL ====================
  
  /// Met à jour le username de l'utilisateur
  Future<bool> updateUsername(String newUsername) async {
    try {
      String? userId = getCurrentUserId();
      if (userId == null) return false;
      
      // Vérifier si le username n'est pas déjà pris
      Map<String, dynamic>? existing = await getUserByUsername(newUsername);
      if (existing != null && existing['email'] != _auth.currentUser?.email) {
        return false; // Username déjà utilisé
      }
      
      await _firestore.collection('users').doc(userId).update({
        'username': newUsername,
      });
      return true;
    } catch (e) {
      print('Erreur mise à jour username: $e');
      return false;
    }
  }

  /// Met à jour le nom de l'utilisateur
  Future<void> updateName(String name, String firstname) async {
    try {
      String? userId = getCurrentUserId();
      if (userId == null) return;
      
      await _firestore.collection('users').doc(userId).update({
        'name': name,
        'firstname': firstname,
      });
      print('Nom mis à jour');
    } catch (e) {
      print('Erreur: $e');
    }
  }

  // ==================== STREAMS (ÉCOUTE EN TEMPS RÉEL) ====================
  
  /// Écoute les changements des données de l'utilisateur connecté
  Stream<DocumentSnapshot> streamCurrentUserData() {
    String? userId = getCurrentUserId();
    if (userId == null) return const Stream.empty();
    
    return _firestore.collection('users').doc(userId).snapshots();
  }

  /// Écoute les changements des statistiques de l'utilisateur connecté
  Stream<Map<String, dynamic>?> streamUserStats() {
    return streamCurrentUserData().map((doc) {
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['stats'] as Map<String, dynamic>;
      }
      return null;
    });
  }

  // ==================== SUPPRESSION ====================
  
  /// Supprime le compte utilisateur (Firebase Auth + Firestore)
  Future<bool> deleteAccount() async {
    try {
      String? userId = getCurrentUserId();
      if (userId == null) return false;
      
      // Supprimer le document Firestore
      await _firestore.collection('users').doc(userId).delete();
      
      // Supprimer l'utilisateur de Firebase Auth
      await _auth.currentUser?.delete();
      
      print('Compte supprimé avec succès');
      return true;
    } catch (e) {
      print('Erreur suppression compte: $e');
      return false;
    }
  }
}