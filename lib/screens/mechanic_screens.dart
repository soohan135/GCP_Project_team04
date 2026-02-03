import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/review.dart';
import 'package:intl/intl.dart';
import '../services/schedule_service.dart';
import '../utils/mechanic_design.dart';

class ReceivedRequestsScreen extends StatelessWidget {
  final AppUser appUser;
  const ReceivedRequestsScreen({super.key, required this.appUser});

  @override
  Widget build(BuildContext context) {
    // Transparent Scaffold to show WrenchBackground from MainLayout
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_centers')
            .doc(appUser.serviceCenterId)
            .collection('receive_estimate')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: MechanicColor.primary500),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(
              icon: LucideIcons.inbox,
              title: '받은 요청이 없습니다.',
              subtitle: '고객님이 보내신 견적 요청이 여기에 표시됩니다.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              return _ReceivedRequestCard(
                data: data,
                requestId: doc.id,
                appUser: appUser,
              );
            },
          );
        },
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
          Icon(icon, size: 64, color: MechanicColor.primary300),
          const SizedBox(height: 24),
          Text(title, style: MechanicTypography.subheader),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: MechanicTypography.body.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ReceivedRequestCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String requestId;
  final AppUser appUser;

  const _ReceivedRequestCard({
    required this.data,
    required this.requestId,
    required this.appUser,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final isResponded = status == 'responded';
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final dateStr = createdAt != null
        ? DateFormat('MM/dd HH:mm').format(createdAt)
        : '';

    // Status Badge Helpers
    Color badgeBg;
    Color badgeText;
    String badgeLabel;

    if (status == 'reserved') {
      badgeBg = Colors.green.shade50;
      badgeText = Colors.green.shade700;
      badgeLabel = '예약 확정';
    } else if (isResponded) {
      badgeBg = MechanicColor.primary50;
      badgeText = MechanicColor.primary500;
      badgeLabel = '견적 발송됨';
    } else {
      badgeBg = MechanicColor.primary100;
      badgeText = MechanicColor.primary700;
      badgeLabel = '견적 요청';
    }

    return MechanicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    color: badgeText,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  color: MechanicColor.primary400,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (data['imageUrl'] != null)
                GestureDetector(
                  onTap: () => _showImageDialog(context, data['imageUrl']),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Hero(
                      tag: data['imageUrl'] + requestId, // Unique tag
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
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.image, color: Colors.grey),
                ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '요청 고객: ${data['userEmail'] ?? '익명'}',
                      style: MechanicTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['userRequest'] ?? '요청 사항 없음',
                      style: MechanicTypography.body.copyWith(
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (status == 'reserved' &&
                        data['confirmedDate'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.calendarCheck,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '방문 예정: ${DateFormat('yyyy.MM.dd').format((data['confirmedDate'] as Timestamp).toDate())}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isResponded || status == 'reserved'
                  ? null
                  : () => _showEstimateInputDialog(context, data, requestId),
              style: ElevatedButton.styleFrom(
                backgroundColor: MechanicColor.primary500,
                foregroundColor: Colors.white,
                disabledBackgroundColor: MechanicColor.primary100,
                disabledForegroundColor: MechanicColor.primary600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                status == 'reserved'
                    ? '예약 확정됨'
                    : (isResponded ? '견적 전송 완료' : '견적 보내기'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
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
              tag: imageUrl + requestId,
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
            title: Text(
              '견적 작성',
              style: MechanicTypography.headline.copyWith(fontSize: 20),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: '수리 비용 (원)',
                      hintText: '예: 300000',
                      labelStyle: TextStyle(color: Colors.grey.shade600),
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: MechanicColor.primary500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '수리가능 일자',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: MechanicColor.primary600,
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
                              color: MechanicColor.primary50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: MechanicColor.primary200,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.calendar,
                                  size: 16,
                                  color: MechanicColor.primary500,
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
                                primary: MechanicColor.primary500,
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
                      foregroundColor: MechanicColor.primary600,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationController,
                    decoration: InputDecoration(
                      labelText: '예상 소요시간',
                      hintText: '예: 2~3일',
                      focusedBorder: const UnderlineInputBorder(
                        borderSide: BorderSide(color: MechanicColor.primary500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: '추가 안내 사항',
                      hintText: '부품 재고 확인 필요 등...',
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: MechanicColor.primary500),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소', style: TextStyle(color: Colors.grey)),
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
                    final responseRef = FirebaseFirestore.instance
                        .collection('users')
                        .doc(userId)
                        .collection('response_estimate')
                        .doc('${shopId}_$estimateId');

                    batch.set(responseRef, {
                      'estimateId': estimateId,
                      'shopId': shopId,
                      'shopName': shopName,
                      'shopAddress': shopAddress,
                      'price': priceController.text.trim(),
                      'duration': durationController.text.trim(),
                      'repairCompletionDates': selectedDates,
                      'description': descriptionController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    await batch.commit();

                    // 일정 추가 (Firestore)
                    try {
                      final scheduleService = ScheduleService();
                      for (final date in selectedDates) {
                        await scheduleService.addSchedule(
                          shopId: shopId,
                          date: date,
                          title: '수리 예정: ${requestData['userEmail'] ?? '고객'}',
                          description:
                              '${requestData['userRequest'] ?? '수리 요청'} - ${descriptionController.text}',
                          customerEmail: requestData['userEmail'] ?? 'unknown',
                        );
                      }
                    } catch (e) {
                      print('Error adding schedule: $e');
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('견적과 일정이 성공적으로 전송되었습니다.')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('전송 실패: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MechanicColor.primary500,
                  foregroundColor: Colors.white,
                ),
                child: const Text('보내기'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class ReviewManagementScreen extends StatelessWidget {
  final AppUser appUser;
  const ReviewManagementScreen({super.key, required this.appUser});

  @override
  Widget build(BuildContext context) {
    // Transparent Scaffold to show Wrench from MainLayout
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_centers')
            .doc(appUser.serviceCenterId)
            .collection('reviews')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: MechanicColor.primary500),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(
              icon: LucideIcons.star,
              title: '등록된 리뷰가 없습니다.',
              subtitle: '작성된 리뷰와 평점을 관리할 수 있습니다.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final review = Review.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );
              return _ReviewCard(review: review);
            },
          );
        },
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
          Icon(icon, size: 64, color: MechanicColor.primary300),
          const SizedBox(height: 24),
          Text(title, style: MechanicTypography.subheader),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: MechanicTypography.body.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final Review review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return MechanicCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: MechanicColor.primary100,
                radius: 20,
                child: Text(
                  review.userName.isNotEmpty ? review.userName[0] : '?',
                  style: const TextStyle(
                    color: MechanicColor.primary700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
                      style: MechanicTypography.body.copyWith(
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
            style: MechanicTypography.body.copyWith(height: 1.5),
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
}
