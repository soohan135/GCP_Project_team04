import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gcp_project_team_04/services/chat_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'chat_detail_screen.dart';
import 'package:gcp_project_team_04/services/schedule_service.dart';
import '../widgets/custom_search_bar.dart';
import '../utils/consumer_design.dart';

class ShopResponsesScreen extends StatefulWidget {
  const ShopResponsesScreen({super.key});

  @override
  State<ShopResponsesScreen> createState() => _ShopResponsesScreenState();
}

class _ShopResponsesScreenState extends State<ShopResponsesScreen> {
  String? _expandedCardId;
  final Map<String, DateTime> _selectedDates = {};
  String _searchQuery = '';

  Future<void> _startChat(
    BuildContext context,
    String shopId,
    String shopName,
    String estimateId,
  ) async {
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
            builder: (context) =>
                ChatDetailScreen(roomId: roomId, otherUserName: shopName),
          ),
        );
      } else {
        // Handle no mechanic found
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('해당 정비소에 연결된 정비사가 없습니다.')));
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('채팅 시작에 실패했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 100), // Header spacing
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
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
              Text('정비소 응답 현황', style: ConsumerTypography.h1),
              const SizedBox(height: 4),
              Text(
                '정비소에서 보낸 견적 제안을 확인하세요.',
                style: ConsumerTypography.bodyMedium,
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
                return const Center(
                  child: CircularProgressIndicator(
                    color: ConsumerColor.brand500,
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              final allDocs = snapshot.data!.docs;
              final filteredDocs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final query = _searchQuery.toLowerCase();
                final shopName = (data['shopName'] ?? '')
                    .toString()
                    .toLowerCase();
                final shopAddress = (data['shopAddress'] ?? '')
                    .toString()
                    .toLowerCase();
                return shopName.contains(query) || shopAddress.contains(query);
              }).toList();

              return Column(
                children: [
                  Expanded(
                    child: filteredDocs.isEmpty
                        ? _buildEmptyState(isSearch: _searchQuery.isNotEmpty)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              final docId = doc.id;
                              final isExpanded = _expandedCardId == docId;

                              return _buildResponseCard(
                                context,
                                data,
                                docId,
                                isExpanded,
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
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

    final status = data['status'];
    final isReserved = status == 'reserved';
    final confirmedDate = (data['confirmedDate'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isExpanded ? ConsumerColor.brand300 : ConsumerColor.slate100,
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isExpanded
                ? ConsumerColor.brand100.withOpacity(0.3)
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
                      color: isReserved
                          ? Colors.green.withOpacity(0.1)
                          : ConsumerColor.brand50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      LucideIcons.warehouse,
                      color: isReserved ? Colors.green : ConsumerColor.brand500,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              data['shopName'] ?? '정비소',
                              style: ConsumerTypography.h2.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            if (isReserved) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  '예약확정',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.mapPin,
                              size: 12,
                              color: ConsumerColor.slate400,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                data['shopAddress'] ?? '주소 정보 없음',
                                style: ConsumerTypography.bodySmall,
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

                  if (isReserved) ...[
                    const Text(
                      '확정된 방문 일자',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.calendarCheck,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            confirmedDate != null
                                ? DateFormat(
                                    'yyyy년 MM월 dd일 (E)',
                                    'ko_KR',
                                  ).format(confirmedDate)
                                : '날짜 정보 없음',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
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
                  ],
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
                            if (data['shopId'] != null &&
                                data['estimateId'] != null) {
                              _startChat(
                                context,
                                data['shopId'],
                                data['shopName'] ?? '정비소',
                                data['estimateId'],
                              );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: ConsumerColor.brand200,
                            ),
                            foregroundColor: ConsumerColor.brand600,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
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
                          onPressed: isReserved
                              ? null
                              : () {
                                  if (selectedDate == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('방문하실 날짜를 선택해주세요.'),
                                      ),
                                    );
                                    return;
                                  }
                                  _confirmReservation(
                                    context,
                                    docId,
                                    data,
                                    selectedDate,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isReserved
                                ? ConsumerColor.slate200
                                : ConsumerColor.brand500,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            isReserved ? '예약 확정됨' : '예약하기',
                            style: const TextStyle(fontWeight: FontWeight.bold),
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

  Future<void> _confirmReservation(
    BuildContext context,
    String userDocId,
    Map<String, dynamic> data,
    DateTime selectedDate,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final shopId = data['shopId'];
      final estimateId = data['estimateId'];

      if (shopId == null || estimateId == null) {
        throw Exception('필수 정보가 없습니다.');
      }

      final batch = FirebaseFirestore.instance.batch();

      // 1. 유저 문서 업데이트
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('response_estimate')
          .doc(userDocId);

      // Parse duration if available (e.g. "3일" -> 3)
      int? durationDays;
      final durationStr = data['duration']?.toString();
      if (durationStr != null) {
        final match = RegExp(r'\d+').firstMatch(durationStr);
        if (match != null) {
          durationDays = int.parse(match.group(0)!);
        }
      }

      batch.update(userDocRef, {
        'status': 'reserved',
        'confirmedDate': selectedDate,
        'confirmedDuration': durationDays,
        'reservedAt': FieldValue.serverTimestamp(),
      });

      // 2. 정비소 문서 업데이트 (estimateId로 검색 필요)
      final shopQuery = await FirebaseFirestore.instance
          .collection('service_centers')
          .doc(shopId)
          .collection('receive_estimate')
          .where('estimateId', isEqualTo: estimateId)
          .get();

      if (shopQuery.docs.isNotEmpty) {
        final shopDocRef = shopQuery.docs.first.reference;
        batch.update(shopDocRef, {
          'status': 'reserved',
          'confirmedDate': selectedDate,
          'confirmedDuration': durationDays,
          'reservedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      // 3. 정비소 일정에 추가
      try {
        final scheduleService = ScheduleService();
        await scheduleService.addSchedule(
          shopId: shopId,
          date: selectedDate,
          title: '예약 확정: ${user.email ?? '고객'}',
          description:
              '수리 예약 (견적가: ${data['price']}원) - ${data['description'] ?? ''}',
          customerEmail: user.email ?? 'unknown',
          duration: durationDays,
        );
      } catch (e) {
        print('일정 추가 실패: $e');
        // 일정 추가 실패가 예약 전체 실패로 이어지게 할지는 선택 사항.
        // 여기서는 로그만 남김.
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('예약이 확정되었습니다.')));

      setState(() {
        _expandedCardId = null; // 접기
      });
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('예약 처리에 실패했습니다: $e')));
    }
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    bool isPrice = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: ConsumerColor.slate400),
        const SizedBox(width: 8),
        Text(label, style: ConsumerTypography.bodySmall),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrice ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isPrice ? ConsumerColor.brand600 : ConsumerColor.slate800,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState({bool isSearch = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: ConsumerColor.brand50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearch ? Icons.search_off : LucideIcons.clipboardList,
              size: 48,
              color: ConsumerColor.brand300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isSearch ? '검색 결과가 없습니다.' : '받은 응답이 없습니다.',
            style: ConsumerTypography.h2,
          ),
          const SizedBox(height: 8),
          Text(
            isSearch ? '다른 검색어를 입력해 보세요.' : '정비소에서 견적을 보내면 여기에 표시됩니다.',
            style: ConsumerTypography.bodyMedium,
          ),
        ],
      ),
    );
  }
}
