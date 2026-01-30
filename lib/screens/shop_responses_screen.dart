import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gcp_project_team_04/services/chat_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'chat_detail_screen.dart';

class ShopResponsesScreen extends StatefulWidget {
  const ShopResponsesScreen({super.key});

  @override
  State<ShopResponsesScreen> createState() => _ShopResponsesScreenState();
}

class _ShopResponsesScreenState extends State<ShopResponsesScreen> {
  String? _expandedCardId;
  final Map<String, DateTime> _selectedDates = {};

  Future<void> _startChat(BuildContext context, String shopId, String shopName, String estimateId) async {
    final chatService = ChatService();
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) {
      // Handle user not logged in
      return;
    }

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('serviceCenterId', isEqualTo: shopId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final mechanic = querySnapshot.docs.first;
        final mechanicId = mechanic.id;

        final roomId = await chatService.getOrCreateChatRoom(
          mechanicId,
          estimateId: estimateId,
          shopName: shopName,
          consumerId: currentUserId,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              roomId: roomId,
              otherUserName: shopName,
            ),
          ),
        );
      } else {
        // Handle no mechanic found
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해당 정비소에 연결된 정비사가 없습니다.')),
        );
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅 시작에 실패했습니다: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '정비소 응답 현황',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  '정비소에서 보낸 견적 제안을 확인하세요.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('response_estimate')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final docId = doc.id;
                    final isExpanded = _expandedCardId == docId;

                    return _buildResponseCard(context, data, docId, isExpanded);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
    bool isExpanded,
  ) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final dateStr = createdAt != null
        ? DateFormat('MM/dd HH:mm').format(createdAt)
        : '';
    final repairDates =
        (data['repairCompletionDates'] as List<dynamic>?)
            ?.map((d) => (d as Timestamp).toDate())
            .toList() ??
        [];

    final selectedDate = _selectedDates[docId];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isExpanded ? Colors.blueAccent : const Color(0xFFE2E8F0),
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? Colors.blueAccent.withOpacity(0.05)
                : Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header (Always Visible)
          InkWell(
            onTap: () {
              setState(() {
                _expandedCardId = isExpanded ? null : docId;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.warehouse,
                      color: Colors.blueAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['shopName'] ?? '정비소',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 12,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                data['shopAddress'] ?? '주소 정보 없음',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        isExpanded
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          if (isExpanded) ...[
            const Divider(height: 1, indent: 16, endIndent: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(
                    LucideIcons.banknote,
                    '견적 금액',
                    '₩${data['price']}',
                    isPrice: true,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    LucideIcons.clock,
                    '예상 수리기간',
                    data['duration'] ?? '미정',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '방문 가능 일자 선택',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: repairDates.map((date) {
                      final isDateSelected =
                          selectedDate != null &&
                          selectedDate.year == date.year &&
                          selectedDate.month == date.month &&
                          selectedDate.day == date.day;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDates[docId] = date;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDateSelected
                                ? Colors.blueAccent
                                : Colors.blueAccent.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDateSelected
                                  ? Colors.blueAccent
                                  : Colors.blueAccent.withOpacity(0.1),
                            ),
                          ),
                          child: Text(
                            DateFormat('MM/dd (E)', 'ko_KR').format(date),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDateSelected
                                  ? Colors.white
                                  : Colors.blueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (data['description'] != null &&
                      data['description'].toString().isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      '정비사 한마디',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        data['description'].toString(),
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (data['shopId'] != null && data['estimateId'] != null) {
                              _startChat(context, data['shopId'], data['shopName'] ?? '정비소', data['estimateId']);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blueAccent),
                            foregroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            '상담하기',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedDate == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('방문하실 날짜를 선택해주세요.'),
                                ),
                              );
                              return;
                            }
                            // TODO: 예약 확정 로직
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            '예약하기',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isPrice = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrice ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isPrice ? Colors.blueAccent : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.clipboardList,
            size: 64,
            color: Colors.grey.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            '받은 응답이 없습니다.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '정비소에서 견적을 보내면 여기에 표시됩니다.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
