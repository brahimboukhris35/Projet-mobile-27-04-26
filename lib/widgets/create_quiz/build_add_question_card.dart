import 'package:flutter/material.dart';

class AddQuestionCard extends StatelessWidget {
  final TextEditingController questionController;
  final List<TextEditingController> optionControllers;
  final TextEditingController pointsController;
  final int correctAnswerIndex;
  final int questionPoints;
  final String? questionError;
  final List<String?> optionErrors;
  final String? pointsError;
  final VoidCallback onAddQuestion;
  final ValueChanged<int> onCorrectAnswerChanged;
  final ValueChanged<int> onPointsChanged;

  const AddQuestionCard({
    super.key,
    required this.questionController,
    required this.optionControllers,
    required this.correctAnswerIndex,
    required this.pointsController,
    required this.questionPoints,
    required this.questionError,
    required this.optionErrors,
    required this.pointsError,
    required this.onAddQuestion,
    required this.onCorrectAnswerChanged,
    required this.onPointsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_circle, color: Color(0xFF4FC3F7), size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Ajouter une question',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: questionController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Posez votre question ici...',
                errorText: questionError,
                errorStyle: const TextStyle(color: Colors.red, fontSize: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFBDC8D0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            
            const Text(
              'Réponses (Sélectionnez la bonne)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF3E484F)),
            ),
            const SizedBox(height: 8),
            for (int i = 0; i < 4; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Radio<int>(
                      value: i,
                      groupValue: correctAnswerIndex,
                      onChanged: (value) => onCorrectAnswerChanged(value!),
                      activeColor: const Color(0xFF81C784),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: optionControllers[i],
                        decoration: InputDecoration(
                          hintText: 'Option ${i + 1}',
                          errorText: optionErrors[i],
                          errorStyle: const TextStyle(color: Colors.red, fontSize: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFBDC8D0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 2),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 1),
                          ),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Text(
                  'Points:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF3E484F)),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: '1-100',
                      errorText: pointsError,
                      errorStyle: const TextStyle(color: Colors.red, fontSize: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFBDC8D0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF4FC3F7), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 1),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      if (value.isEmpty) {
                          onPointsChanged(0); 
                        } else {
                          final points = int.tryParse(value) ?? 0;
                          onPointsChanged(points);
                      }
                    },
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onAddQuestion,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Ajouter'),
                      Text('la question', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF81C784),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}