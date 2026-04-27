import 'package:flutter/material.dart';

class DifficultyDropdown extends StatelessWidget {
  final String selectedDifficulty;
  final List<String> difficulties;
  final ValueChanged<String> onChanged;

  const DifficultyDropdown({
    super.key,
    required this.selectedDifficulty,
    required this.difficulties,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Difficulté',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF3E484F)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFBDC8D0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedDifficulty,
              isExpanded: true,
              items: difficulties.map((difficulty) {
                return DropdownMenuItem<String>(
                  value: difficulty,
                  child: Text(difficulty),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ),
        ),
      ],
    );
  }
}