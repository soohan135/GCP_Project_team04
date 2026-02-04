import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'package:gcp_project_team_04/models/app_user.dart';
import 'package:gcp_project_team_04/providers/estimate_provider.dart';
import 'package:gcp_project_team_04/screens/chat_detail_screen.dart';
import 'package:gcp_project_team_04/services/chat_service.dart';
import 'package:gcp_project_team_04/services/auth_service.dart';
import 'package:gcp_project_team_04/widgets/chat_list_item.dart';
import '../widgets/custom_search_bar.dart';
import '../utils/consumer_design.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  String _searchQuery = '';
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

            final allChatRooms = snapshot.data?.docs ?? [];
            final filteredRooms = allChatRooms.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final query = _searchQuery.toLowerCase();
              final shopName = (data['shopName'] ?? '')
                  .toString()
                  .toLowerCase();
              final otherUserName = (data['otherUserName'] ?? '')
                  .toString()
                  .toLowerCase();
              return shopName.contains(query) || otherUserName.contains(query);
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (appUser?.role == UserRole.consumer) ...[
                  const SizedBox(height: 100),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: CustomSearchBar(
                      onSearch: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('채팅', style: ConsumerTypography.h1),
                        const SizedBox(height: 4),
                        Text(
                          '정비소에 문의사항을 보내보세요.',
                          style: ConsumerTypography.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 20),
                ],
                Expanded(
                  child: filteredRooms.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _searchQuery.isNotEmpty
                                    ? '검색 결과가 없습니다.'
                                    : '채팅방이 없습니다.',
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          itemCount: filteredRooms.length,
                          itemBuilder: (context, index) {
                            final room = filteredRooms[index];
                            final roomData =
                                room.data() as Map<String, dynamic>;
                            final participants =
                                roomData['participants'] as List<dynamic>;
                            final estimateId =
                                roomData['estimateId'] as String?;
                            final consumerId =
                                roomData['consumerId'] as String?;

                            return FutureBuilder<AppUser?>(
                              future: _chatService.getOtherParticipantUser(
                                participants,
                                _currentUserId,
                              ),
                              builder: (context, userSnapshot) {
                                final otherUser = userSnapshot.data;

                                return FutureBuilder<Estimate?>(
                                  future:
                                      (estimateId != null && consumerId != null)
                                      ? _chatService.getEstimateDetails(
                                          estimateId,
                                          consumerId,
                                        )
                                      : Future.value(null),
                                  builder: (context, estimateSnapshot) {
                                    final estimate = estimateSnapshot.data;

                                    String title =
                                        otherUser?.displayName ?? '상대방';
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
                                      role: appUser?.role ?? UserRole.consumer,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChatDetailScreen(
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
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
