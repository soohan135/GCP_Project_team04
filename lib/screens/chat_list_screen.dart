import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gcp_project_team_04/models/app_user.dart';
import 'package:gcp_project_team_04/providers/estimate_provider.dart';
import 'package:gcp_project_team_04/screens/chat_detail_screen.dart';
import 'package:gcp_project_team_04/services/chat_service.dart';
import 'package:gcp_project_team_04/widgets/chat_list_item.dart';
import 'package:provider/provider.dart';
import 'package:gcp_project_team_04/services/auth_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return StreamBuilder<AppUser?>(
      stream: authService.appUserStream,
      builder: (context, appUserSnapshot) {
        final appUser = appUserSnapshot.data;

        return StreamBuilder<QuerySnapshot>(
          stream: _chatService.getChatRooms(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('채팅방이 없습니다.'));
            }

            final chatRooms = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.only(top: 16, bottom: 20),
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                final room = chatRooms[index];
                final roomData = room.data() as Map<String, dynamic>;
                final participants = roomData['participants'] as List<dynamic>;
                final estimateId = roomData['estimateId'] as String?;
                final consumerId = roomData['consumerId'] as String?;

                return FutureBuilder<AppUser?>(
                  future: _chatService.getOtherParticipantUser(
                    participants,
                    _currentUserId,
                  ),
                  builder: (context, userSnapshot) {
                    final otherUser = userSnapshot.data;

                    return FutureBuilder<Estimate?>(
                      future: (estimateId != null && consumerId != null)
                          ? _chatService.getEstimateDetails(
                              estimateId,
                              consumerId,
                            )
                          : Future.value(null),
                      builder: (context, estimateSnapshot) {
                        final estimate = estimateSnapshot.data;

                        String title = otherUser?.displayName ?? '상대방';
                        if (appUser?.role == UserRole.consumer) {
                          title =
                              roomData['shopName'] ??
                              otherUser?.displayName ??
                              '정비소';
                        }

                        return ChatListItem(
                          room: room,
                          estimate: estimate,
                          title: title,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  roomId: room.id,
                                  otherUserName: title,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
