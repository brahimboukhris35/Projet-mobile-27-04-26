import 'package:flutter/material.dart';

// Enum pour les statuts
enum QuizStatus {
  draft,    // Brouillon (expire dans 7 jours)
  private,  // Privé (permanent, seulement le créateur)
  public,   // Public (tout le monde)
}

extension QuizStatusExtension on QuizStatus {
  String get label {
    switch (this) {
      case QuizStatus.draft:
        return 'Brouillon';
      case QuizStatus.private:
        return 'Privé';
      case QuizStatus.public:
        return 'Public';
    }
  }
  
  String get value {
    switch (this) {
      case QuizStatus.draft:
        return 'draft';
      case QuizStatus.private:
        return 'private';
      case QuizStatus.public:
        return 'public';
    }
  }
  
  IconData get icon {
    switch (this) {
      case QuizStatus.draft:
        return Icons.edit_note;
      case QuizStatus.private:
        return Icons.lock;
      case QuizStatus.public:
        return Icons.public;
    }
  }
  
  Color get color {
    switch (this) {
      case QuizStatus.draft:
        return Colors.orange;
      case QuizStatus.private:
        return Colors.blue;
      case QuizStatus.public:
        return Colors.green;
    }
  }
  
  static QuizStatus fromString(String value) {
    switch (value) {
      case 'private': return QuizStatus.private;
      case 'public': return QuizStatus.public;
      default: return QuizStatus.draft;
    }
  }
}

// Modèle de catégorie
class Category {
  final String name;
  final String icon;
  final Color color;
  
  const Category({
    required this.name,
    required this.icon,
    required this.color,
  });
}

// Données statiques des catégories
final List<Category> categories = [
  const Category(name: 'Culture', icon: '📚', color: Color(0xFF4FC3F7)),
  const Category(name: 'Cinéma', icon: '🎬', color: Color(0xFFE1BEE7)),
  const Category(name: 'Football', icon: '⚽', color: Color(0xFF81C784)),
  const Category(name: 'Musique', icon: '🎵', color: Color(0xFFFFB954)),
  const Category(name: 'Science', icon: '🧪', color: Color(0xFFFFCDD2)),
  const Category(name: 'Art', icon: '🎨', color: Color(0xFFB39DDB)),
  const Category(name: 'Histoire', icon: '🏛️', color: Color(0xFFFF8A65)),
  const Category(name: 'Géographie', icon: '🌍', color: Color(0xFF4FC3F7)),
  const Category(name: 'Technologie', icon: '💻', color: Color(0xFF81C784)),
  const Category(name: 'Sport', icon: '🏆', color: Color(0xFFFFB954)),
];

final List<String> difficulties = ['Facile', 'Moyen', 'Difficile'];