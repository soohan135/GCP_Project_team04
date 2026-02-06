import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import '../utils/consumer_design.dart';
import '../utils/mechanic_design.dart';
import 'package:flutter/services.dart';

class ChatDetailScreen extends StatefulWidget {
  final String roomId;
  final String otherUserName;

  const ChatDetailScreen({
    super.key,
    required this.roomId,
    required this.otherUserName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.enter) {
          if (HardwareKeyboard.instance.isShiftPressed) {
            return KeyEventResult.ignored;
          }
          _sendMessage();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final text = _messageController.text.trim();
    _messageController.clear();

    try {
      await _chatService.sendMessage(widget.roomId, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('메시지 전송 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<AppUser?>(
      stream: authService.appUserStream,
      builder: (context, snapshot) {
        final appUser = snapshot.data;
        final isMechanic = appUser?.role == UserRole.mechanic;

        return Scaffold(
          backgroundColor: isMechanic
              ? MechanicColor.background
              : ConsumerColor.background,
          appBar: AppBar(
            title: Text(
              widget.otherUserName,
              style: isMechanic
                  ? MechanicTypography.subheader.copyWith(
                      fontWeight: FontWeight.bold,
                    )
                  : ConsumerTypography.h2,
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: isMechanic
                ? MechanicColor.primary100
                : ConsumerColor.brand200,
            foregroundColor: isMechanic ? Colors.black : ConsumerColor.slate800,
            surfaceTintColor: isMechanic
                ? MechanicColor.primary100
                : ConsumerColor.brand200,
          ),
          body: isMechanic
              ? WrenchBackground(child: _buildChatBody(context, true))
              : SearchBackground(
                  offset: const Offset(-10, -40),
                  child: _buildChatBody(context, false),
                ),
        );
      },
    );
  }

  Widget _buildChatBody(BuildContext context, bool isMechanic) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _chatService.getMessages(widget.roomId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.messageCircle,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '대화를 시작해보세요!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              final messages = snapshot.data!.docs;

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final data = messages[index].data() as Map<String, dynamic>;
                  final isMe = data['senderId'] == _currentUserId;
                  final timestamp = data['createdAt'] as Timestamp?;

                  return _buildMessageBubble(
                    data['text'],
                    isMe,
                    timestamp?.toDate(),
                    isMechanic,
                  );
                },
              );
            },
          ),
        ),
        _buildMessageInput(isMechanic),
      ],
    );
  }

  Widget _buildMessageBubble(
    String text,
    bool isMe,
    DateTime? time,
    bool isMechanic,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isMe && time != null)
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 2),
              child: Text(
                DateFormat('HH:mm').format(time),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? null : Colors.white,
                gradient: isMe
                    ? (isMechanic
                          ? MechanicColor.pointGradient
                          : ConsumerColor.pointGradient)
                    : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 2),
                  bottomRight: Radius.circular(isMe ? 2 : 18),
                ),
                boxShadow: isMe
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  color: isMe ? Colors.white : ConsumerColor.slate800,
                  fontSize: 15,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (!isMe && time != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Text(
                DateFormat('HH:mm').format(time),
                style: TextStyle(
                  fontSize: 10,
                  color: isMechanic ? Colors.grey : ConsumerColor.slate400,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isMechanic) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isMechanic
                    ? Colors.grey.shade100
                    : ConsumerColor.slate50,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: '메시지를 입력하세요...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                maxLines: null,
                style: isMechanic
                    ? const TextStyle(fontSize: 15)
                    : const TextStyle(fontSize: 15),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: isMechanic
                  ? MechanicColor.primary500
                  : ConsumerColor.brand500,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.send, color: Colors.white, size: 18),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
