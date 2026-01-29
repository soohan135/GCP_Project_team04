import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/review.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import 'chat_detail_screen.dart';

class ReceivedRequestsScreen extends StatelessWidget {
  final AppUser appUser;
  const ReceivedRequestsScreen({super.key, required this.appUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopId = appUser.serviceCenterId;

    if (shopId == null) {
      return const Scaffold(body: Center(child: Text('소속된 정비소가 없습니다.')));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '견적 요청 현황',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로 들어온 요청들을 확인하고 견적을 보내보세요.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('service_centers')
                    .doc(shopId)
                    .collection('receive_estimate')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(
                      icon: LucideIcons.inbox,
                      title: '받은 요청이 없습니다.',
                      subtitle: '고객님이 보내신 견적 요청이 여기에 표시됩니다.',
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildRequestCard(context, data, doc.id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    Map<String, dynamic> data,
    String requestId,
  ) {
    final theme = Theme.of(context);
    final status = data['status'] ?? 'pending';
    final isResponded = status == 'responded';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final dateStr = createdAt != null
        ? DateFormat('MM/dd HH:mm').format(createdAt)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '견적 요청',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data['imageUrl'] != null)
                GestureDetector(
                  onTap: () => _showImageDialog(context, data['imageUrl']),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Hero(
                      tag: data['imageUrl'],
                      child: Image.network(
                        data['imageUrl'],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.image, color: Colors.grey),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '요청 고객: ${data['userEmail'] ?? '익명'}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '요청 사항: ${data['userRequest'] ?? '없음'}',
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 14,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isResponded
                  ? null
                  : () => _showEstimateInputDialog(context, data, requestId),
              style: ElevatedButton.styleFrom(
                backgroundColor: isResponded ? Colors.grey : Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(isResponded ? '견적 전송 완료' : '견적 작성하기'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEstimateInputDialog(
    BuildContext context,
    Map<String, dynamic> requestData,
    String requestId,
  ) {
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    final descriptionController = TextEditingController();
    List<DateTime> selectedDates = [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('견적 작성'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '수리 비용 (원)',
                      hintText: '예: 300000',
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '수리가능 일자',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (selectedDates.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Column(
                        children: selectedDates.asMap().entries.map((entry) {
                          int idx = entry.key;
                          DateTime date = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blueAccent.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.calendar,
                                  size: 16,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    DateFormat(
                                      'yyyy년 MM월 dd일 (EE)',
                                      'ko_KR',
                                    ).format(date),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setDialogState(() {
                                      selectedDates.removeAt(idx);
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(
                          const Duration(days: 3),
                        ),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Colors.blueAccent,
                                onPrimary: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setDialogState(() {
                          if (!selectedDates.any(
                            (d) =>
                                d.year == picked.year &&
                                d.month == picked.month &&
                                d.day == picked.day,
                          )) {
                            selectedDates.add(picked);
                            selectedDates.sort();
                          }
                        });
                      }
                    },
                    icon: const Icon(LucideIcons.plusCircle, size: 18),
                    label: const Text('일자 추가하기'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blueAccent,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: '예상 소요시간',
                      hintText: '예: 2~3일',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: '추가 안내 사항',
                      hintText: '부품 재고 확인 필요 등...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (priceController.text.isEmpty ||
                      durationController.text.isEmpty ||
                      selectedDates.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('비용, 예상 소요시간, 수리가능 일자를 모두 입력해주세요.'),
                      ),
                    );
                    return;
                  }

                  try {
                    final shopId = appUser.serviceCenterId;
                    final userId = requestData['userId'];
                    final estimateId = requestData['estimateId'];

                    if (shopId == null ||
                        userId == null ||
                        estimateId == null) {
                      throw Exception('필수 정보가 누락되었습니다.');
                    }

                    // 정비소 정보(이름, 주소) 가져오기
                    final shopSnap = await FirebaseFirestore.instance
                        .collection('service_centers')
                        .doc(shopId)
                        .get();

                    final shopData = shopSnap.data();
                    final shopName =
                        shopData?['name'] ?? appUser.displayName ?? '정비소';
                    final shopAddress = shopData?['address'] ?? '주소 정보 없음';

                    final batch = FirebaseFirestore.instance.batch();

                    // 1. 정비소측 요청 문서 업데이트
                    final requestRef = FirebaseFirestore.instance
                        .collection('service_centers')
                        .doc(shopId)
                        .collection('receive_estimate')
                        .doc(requestId);

                    batch.update(requestRef, {
                      'status': 'responded',
                      'offerPrice': priceController.text.trim(),
                      'offerDuration': durationController.text.trim(),
                      'repairCompletionDate': selectedDates.first,
                      'repairCompletionDates': selectedDates,
                      'offerDescription': descriptionController.text.trim(),
                      'respondedAt': FieldValue.serverTimestamp(),
                    });

                    // 2. 고객측 유저 문서 하위 response_estimate 서브컬렉션에 저장
                    // (일관성을 위해 shopId와 estimateId를 조합한 ID 사용)
                    final responseRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('response_estimate')
                        .doc('${shopId}_$estimateId');

                    batch.set(responseRef, {
                      'estimateId': estimateId,
                      'shopId': shopId,
                      'shopName': shopName,
                      'shopAddress': shopAddress, // 정비소 위치
                      'price': priceController.text.trim(), // 견적 금액
                      'duration': durationController.text.trim(), // 예상 수리기간
                      'repairCompletionDates': selectedDates, // 수리가능 날짜 (리스트)
                      'description': descriptionController.text.trim(), // 세부사항
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    await batch.commit();

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('견적이 성공적으로 전송되었습니다.')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('전송 실패: $e')));
                  }
                },
                child: const Text('보내기'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.9),
              ),
            ),
            Hero(
              tag: imageUrl,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  width: MediaQuery.of(context).size.width,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              right: 20,
              top: 40,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.blueAccent.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class ReviewManagementScreen extends StatelessWidget {
  final AppUser appUser;
  const ReviewManagementScreen({super.key, required this.appUser});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopId = appUser.serviceCenterId;

    if (shopId == null) {
      return const Scaffold(body: Center(child: Text('소속된 정비소가 없습니다.')));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '리뷰 관리',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '정비소에 등록된 고객님들의 소중한 리뷰입니다.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('service_centers')
                    .doc(shopId)
                    .collection('reviews')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _buildEmptyState(
                      icon: LucideIcons.star,
                      title: '등록된 리뷰가 없습니다.',
                      subtitle: '작성된 리뷰와 평점을 관리할 수 있습니다.',
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final doc = snapshot.data!.docs[index];
                      final review = Review.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                      return _buildReviewCard(context, review);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, Review review) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                radius: 18,
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0] : '?',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy.MM.dd').format(review.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            review.comment,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          if (review.imageUrl != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                review.imageUrl!,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.amber.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final bool isMechanic;
  final String? shopId;
  const ChatScreen({super.key, this.isMechanic = false, this.shopId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final effectiveCurrentId = isMechanic
        ? (shopId ?? currentUserId)
        : currentUserId;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '채팅 상담',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isMechanic
                      ? '고객님들과 실시간으로 소통이 가능합니다.'
                      : '정비소와 실시간으로 소통이 가능합니다.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ChatService().getChatRooms(userId: effectiveCurrentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final rooms = snapshot.data!.docs;

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: rooms.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final roomData =
                        rooms[index].data() as Map<String, dynamic>;
                    final roomId = rooms[index].id;
                    final participants = List<String>.from(
                      roomData['participants'] ?? [],
                    );
                    final otherUserId = participants.firstWhere(
                      (id) => id != effectiveCurrentId,
                      orElse: () => '',
                    );

                    return FutureBuilder<String>(
                      future: _fetchUserName(otherUserId),
                      builder: (context, nameSnapshot) {
                        final otherUserName = nameSnapshot.data ?? '로딩 중...';
                        final lastMessage = roomData['lastMessage'] ?? '';
                        final lastTime =
                            roomData['lastMessageAt'] as Timestamp?;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 0,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isMechanic
                                ? Colors.blueAccent.withOpacity(0.1)
                                : Colors.orangeAccent.withOpacity(0.1),
                            child: Icon(
                              isMechanic
                                  ? LucideIcons.user
                                  : LucideIcons.warehouse,
                              color: isMechanic
                                  ? Colors.blueAccent
                                  : Colors.orangeAccent,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                otherUserName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (lastTime != null)
                                Text(
                                  _formatTime(lastTime.toDate()),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            lastMessage.isNotEmpty
                                ? lastMessage
                                : '대화 내용이 없습니다.',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  roomId: roomId,
                                  otherUserName: otherUserName,
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
      ),
    );
  }

  Future<String> _fetchUserName(String uid) async {
    if (uid.isEmpty) return '알 수 없음';

    // 1. 유저 컬렉션에서 먼저 확인
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (userSnap.exists) {
      return userSnap.data()?['displayName'] ?? '사용자';
    }

    // 2. 없으면 정비소 컬렉션에서 확인
    final shopSnap = await FirebaseFirestore.instance
        .collection('service_centers')
        .doc(uid)
        .get();
    if (shopSnap.exists) {
      return shopSnap.data()?['name'] ?? '정비소';
    }

    return '알 수 없음';
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    if (difference.inDays == 0) {
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays < 7) {
      return DateFormat('E').format(time);
    } else {
      return DateFormat('MM/dd').format(time);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.messageCircle, size: 64, color: Colors.green),
          const SizedBox(height: 24),
          const Text(
            '진행 중인 채팅이 없습니다.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isMechanic ? '받은 요청 이력을 통해 소통해보세요.' : '정비소 응답 이력을 통해 소통해보세요.',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
