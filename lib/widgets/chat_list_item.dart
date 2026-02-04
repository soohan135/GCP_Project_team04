import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gcp_project_team_04/models/app_user.dart';
import 'package:gcp_project_team_04/providers/estimate_provider.dart';
import 'package:gcp_project_team_04/utils/mechanic_design.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gcp_project_team_04/utils/consumer_design.dart';

class ChatListItem extends StatelessWidget {
  final QueryDocumentSnapshot<Object?> room;
  final Estimate? estimate;
  final String title;
  final VoidCallback onTap;
  final UserRole role;

  const ChatListItem({
    super.key,
    required this.room,
    this.estimate,
    required this.title,
    required this.onTap,
    this.role = UserRole.consumer,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessage = room['lastMessage'] as String? ?? '';
    final imageUrl = estimate?.imageUrl;
    final damage = estimate?.damage;

    final isMechanic = role == UserRole.mechanic;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(isMechanic ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMechanic ? 12 : 24),
          border: Border.all(
            color: isMechanic
                ? MechanicColor.primary100
                : ConsumerColor.slate100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (imageUrl != null)
              Container(
                margin: const EdgeInsets.only(right: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isMechanic ? 8 : 12),
                  child: Image.network(
                    imageUrl,
                    width: isMechanic ? 60 : 70,
                    height: isMechanic ? 60 : 70,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: isMechanic ? 60 : 70,
                        height: isMechanic ? 60 : 70,
                        color: ConsumerColor.slate100,
                        child: const Icon(
                          LucideIcons.image,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(right: 16),
                width: isMechanic ? 60 : 70,
                height: isMechanic ? 60 : 70,
                decoration: BoxDecoration(
                  color: ConsumerColor.slate100,
                  borderRadius: BorderRadius.circular(isMechanic ? 8 : 12),
                ),
                child: Icon(
                  LucideIcons.image,
                  size: isMechanic ? 20 : 24,
                  color: Colors.grey,
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: (isMechanic
                        ? const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          )
                        : ConsumerTypography.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: ConsumerColor.slate800,
                          )),
                  ),
                  const SizedBox(height: 4),
                  if (damage != null)
                    Text(
                      isMechanic ? '손상 유형: $damage' : damage,
                      style: (isMechanic
                          ? const TextStyle(fontSize: 12, color: Colors.grey)
                          : ConsumerTypography.bodySmall.copyWith(
                              color: ConsumerColor.brand600,
                            )),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    lastMessage,
                    style: isMechanic
                        ? const TextStyle(fontSize: 14)
                        : ConsumerTypography.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
