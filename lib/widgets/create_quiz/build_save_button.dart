import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';

class SaveButton extends StatelessWidget {
  final QuizStatus status;
  final VoidCallback onPressed;

  const SaveButton({
    super.key,
    required this.status,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(status == QuizStatus.draft ? Icons.save : 
                   (status == QuizStatus.private ? Icons.lock : Icons.public)),
        label: Text(
          status == QuizStatus.draft ? 'Sauvegarder le brouillon' :
          (status == QuizStatus.private ? 'Sauvegarder en privé' : 'Publier'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: status.color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
      ),
    );
  }
}