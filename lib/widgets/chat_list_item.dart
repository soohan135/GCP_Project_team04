import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gcp_project_team_04/providers/estimate_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ChatListItem extends StatelessWidget {
  final QueryDocumentSnapshot<Object?> room;
  final Estimate? estimate;
  final String title;
  final VoidCallback onTap;

  const ChatListItem({
    super.key,
    required this.room,
    this.estimate,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessage = room['lastMessage'] as String? ?? '';
    final imageUrl = estimate?.imageUrl;
    final damage = estimate?.damage;
    final recommendations = estimate?.recommendations;

    return Card(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: Image.network(
                    imageUrl,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(LucideIcons.imageOff, color: Colors.grey),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (damage != null)
                      Text(
                        '손상 유형: $damage',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    if (recommendations != null && recommendations.isNotEmpty)
                      Text(
                        '부품: ${recommendations.join(', ')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      lastMessage,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
