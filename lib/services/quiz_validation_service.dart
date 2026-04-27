import '../models/quiz_model.dart';

class QuizValidationService {
  // Validation du titre
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Titre requis';
    }
    if (value.length > 50) {
      return 'Titre trop long (max 50 caractères)';
    }
    return null;
  }
  
  // Validation de la description (optionnelle)
  static String? validateDescription(String? value) {
    if (value != null && value.length > 200) {
      return 'Description trop longue (max 200 caractères)';
    }
    return null;
  }
  
  // Validation d'une question
  static String? validateQuestionText(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Question requise';
    }
    if (value.length > 200) {
      return 'Question trop longue';
    }
    return null;
  }
  
  // Validation des options
  static String? validateOptions(List<String> options) {
    for (int i = 0; i < options.length; i++) {
      if (options[i].trim().isEmpty) {
        return 'Option ${i + 1} requise';
      }
    }
    
    // Vérifier les doublons
    final uniqueOptions = options.map((o) => o.trim().toLowerCase()).toSet();
    if (uniqueOptions.length != options.length) {
      return 'Les options doivent être uniques';
    }
    
    return null;
  }
  
  // Validation des points
  static String? validatePoints(int points) {
    if (points < 1) {
      return 'Minimum 1 point';
    }
    if (points > 100) {
      return 'Maximum 100 points';
    }
    return null;
  }
  
  // Validation complète du quiz avant sauvegarde
  static ValidationResult validateQuiz({
    required String title,
    required List<Map<String, dynamic>> questions,
    required QuizStatus status,
  }) {
    // Validation du titre
    final titleError = validateTitle(title);
    if (titleError != null) {
      return ValidationResult(false, titleError, 'title');
    }
    
    // Validation des questions (minimum 1 pour tous)
    if (questions.isEmpty) {
      return ValidationResult(false, 'Ajoutez au moins une question', 'questions');
    }
    //Minimum 10 questions UNIQUEMENT pour PUBLIC
    if (status == QuizStatus.public && questions.length < 10) {
      return ValidationResult(false, 'Pour publier en PUBLIC, ajoutez au moins 10 questions (${questions.length}/10)', 'questions');
    }
    
    // Validation de chaque question
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      
      if (q['text'].toString().trim().isEmpty) {
        return ValidationResult(false, 'Question ${i + 1} est vide', 'question_$i');
      }
      
      final options = List<String>.from(q['options']);
      final optionsError = validateOptions(options);
      if (optionsError != null) {
        return ValidationResult(false, optionsError, 'question_${i}_options');
      }
      
      final points = q['points'] as int;
      final pointsError = validatePoints(points);
      if (pointsError != null) {
        return ValidationResult(false, pointsError, 'question_${i}_points');
      }
    }
    
    return ValidationResult(true, null, null);
  }
  
  // Obtenir une catégorie par son nom
  static Category? getCategoryByName(String name) {
    try {
      return categories.firstWhere((c) => c.name == name);
    } catch (e) {
      return categories.first;
    }
  }
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? errorField; // Pour savoir quel champ est en erreur
  
  ValidationResult(this.isValid, this.errorMessage, this.errorField);
}