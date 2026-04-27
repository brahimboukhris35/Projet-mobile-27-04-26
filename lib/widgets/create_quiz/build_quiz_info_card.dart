import 'package:flutter/material.dart';

class QuizInfoCard extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final String selectedCategory;
  final String selectedIcon;
  final Color selectedColor;
  final String? titleError;
  final String? descriptionError;
  final VoidCallback onCategoryChanged;
  final VoidCallback onDifficultyChanged;
  final Widget categoryDropdown;
  final Widget difficultyDropdown;

  const QuizInfoCard({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.selectedCategory,
    required this.selectedIcon,
    required this.selectedColor,
    required this.titleError,
    required this.descriptionError,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
    required this.categoryDropdown,
    required this.difficultyDropdown,
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
            // Titre
            const Text('Titre du quiz', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: 'Entrez le titre...',
                errorText: titleError,
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
            
            // Description
            const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'De quoi parle votre quiz ?',
                errorText: descriptionError,
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
            
            // Catégorie + Difficulté
            Row(
              children: [
                Expanded(child: categoryDropdown),
                const SizedBox(width: 16),
                Expanded(child: difficultyDropdown),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Aperçu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selectedColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: selectedColor.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: selectedColor, borderRadius: BorderRadius.circular(12)),
                    child: Center(child: Text(selectedIcon, style: const TextStyle(fontSize: 28))),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aperçu de la catégorie', style: TextStyle(fontSize: 12, color: Color(0xFF6E7980))),
                        const SizedBox(height: 4),
                        Text(selectedCategory, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}