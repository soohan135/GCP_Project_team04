import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/estimate_provider.dart';

class EstimateDetailScreen extends StatelessWidget {
  final Estimate estimate;

  const EstimateDetailScreen({super.key, required this.estimate});

  @override
  Widget build(BuildContext context) {
    // 날짜 포맷팅 (ISO 문자열에서 보기 좋게 변환)
    String formattedDate = estimate.date;
    try {
      final date = DateTime.parse(estimate.date);
      formattedDate =
          '${date.year}년 ${date.month}월 ${date.day}일 ${date.hour}시 ${date.minute}분';
    } catch (_) {}

    return Scaffold(
      appBar: AppBar(
        title: const Text('견적 상세'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태 뱃지 및 제목
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: estimate.status == '수리완료'
                        ? Colors.blueAccent.withOpacity(0.1)
                        : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    estimate.status,
                    style: TextStyle(
                      color: estimate.status == '수리완료'
                          ? Colors.blueAccent
                          : Colors.amber[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              estimate.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // 견적 이미지
            if (estimate.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  estimate.imageUrl!,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            // 상세 정보 카드
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
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
                  _buildDetailRow('손상 부위', estimate.damage),
                  const Divider(height: 32),
                  _buildDetailRow('예상 비용', estimate.price, isPrice: true),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 권장 작업 리스트
            const Text(
              '권장 작업 내용',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (estimate.recommendations.isNotEmpty)
              ...estimate.recommendations.map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text(
                '권장 작업 내용이 없습니다.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isPrice = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrice ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: isPrice ? Colors.blueAccent : Colors.black,
          ),
        ),
      ],
    );
  }
}
