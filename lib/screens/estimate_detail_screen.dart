import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../providers/estimate_provider.dart';
import '../providers/shop_provider.dart';
import 'select_shops_screen.dart';
import '../utils/consumer_design.dart';

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
      backgroundColor: ConsumerColor.brand50,
      appBar: AppBar(
        title: Text('견적 상세', style: ConsumerTypography.h2),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
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
                    color: estimate.status == '수리 완료'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    estimate.status,
                    style: TextStyle(
                      color: estimate.status == '수리 완료'
                          ? Colors.green
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
            Text(estimate.title, style: ConsumerTypography.h1),
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
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: ConsumerColor.brand100),
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
                  if (estimate.realPrice != null) ...[
                    const Divider(height: 32),
                    _buildDetailRow(
                      '실제 수리 금액',
                      estimate.realPrice!,
                      isPrice: true,
                      isReal: true,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 권장 작업 리스트
            Text('권장 작업 내용', style: ConsumerTypography.h2),
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

            const SizedBox(height: 40),

            // 수리 완료 버튼 (수리 완료가 아닌 경우에만 표시하거나, 수정 가능하게 함)
            if (estimate.realPrice == null) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => _sendRequestToShops(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: Colors.blueAccent,
                      width: 1.5,
                    ),
                    foregroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    '주변 정비소에 수리요청 보내기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _showRepairCompleteDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ConsumerColor.brand500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '수리 완료',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _sendRequestToShops(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectShopsScreen(estimate: estimate),
      ),
    );
  }

  void _showRepairCompleteDialog(BuildContext ctx) {
    final TextEditingController priceController = TextEditingController();

    showDialog(
      context: ctx,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: ConsumerColor.brand500, width: 2),
          ),
          title: const Text('수리 완료'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('실제 수리 금액을 입력해 주세요.'),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '실제 수리 금액',
                  hintText: '예: 150,000원',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (priceController.text.isNotEmpty) {
                  try {
                    final provider =
                        // ignore: use_build_context_synchronously
                        ctx.read<EstimateProvider>();
                    await provider.updateRealPrice(
                      estimate.id,
                      priceController.text,
                    );
                    // ignore: use_build_context_synchronously
                    Navigator.pop(context); // 다이얼로그 닫기
                    // ignore: use_build_context_synchronously
                    Navigator.pop(ctx); // 상세 페이지 닫기 (미리보기로 돌아가기)
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('수리 완료 정보가 저장되었습니다.')),
                    );
                  } catch (e) {
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
                    );
                  }
                }
              },
              child: const Text('저장'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isPrice = false,
    bool isReal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isReal ? Colors.green : Colors.grey,
            fontWeight: isReal ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: isPrice ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: isReal
                ? Colors.green
                : (isPrice ? Colors.blueAccent : Colors.black),
          ),
        ),
      ],
    );
  }
}
