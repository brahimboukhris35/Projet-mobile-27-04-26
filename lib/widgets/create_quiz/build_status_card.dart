import 'package:flutter/material.dart';
import '../../models/quiz_model.dart';

class QuizStatusCard extends StatelessWidget {
  final QuizStatus selectedStatus;
  final ValueChanged<QuizStatus> onStatusChanged;

  const QuizStatusCard({
    super.key,
    required this.selectedStatus,
    required this.onStatusChanged,
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
            const Text(
              'Statut du quiz',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: QuizStatus.values.map((status) {
                final isSelected = selectedStatus == status;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onStatusChanged(status),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? status.color.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? status.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(status.icon, color: isSelected ? status.color : Colors.grey, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            status.label,
                            style: TextStyle(
                              color: isSelected ? status.color : Colors.grey,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selectedStatus.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(selectedStatus.icon, color: selectedStatus.color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      selectedStatus == QuizStatus.draft ? 'Brouillon : expirera dans 7 jours si non publié' :
                      (selectedStatus == QuizStatus.private ? 'Privé : visible uniquement par vous' : 'Public : visible par tous les utilisateurs'),
                      style: TextStyle(fontSize: 12, color: selectedStatus.color),
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