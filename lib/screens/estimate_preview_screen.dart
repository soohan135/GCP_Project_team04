import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/estimate_provider.dart';
import 'estimate_detail_screen.dart';

class EstimatePreviewScreen extends StatefulWidget {
  const EstimatePreviewScreen({super.key});

  @override
  State<EstimatePreviewScreen> createState() => _EstimatePreviewScreenState();
}

class _EstimatePreviewScreenState extends State<EstimatePreviewScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EstimateProvider>(
      builder: (context, provider, child) {
        final estimates = provider.estimates;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '견적 미리보기',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  if (estimates.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '총 ${estimates.length}개의 저장된 견적이 있습니다.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading && estimates.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : estimates.isEmpty
                  ? _buildEmptyView()
                  : Scrollbar(
                      controller: _scrollController,
                      thickness: 6,
                      radius: const Radius.circular(10),
                      thumbVisibility: true,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        itemCount: estimates.length,
                        itemBuilder: (context, index) {
                          final est = estimates[index];
                          return _buildEstimateItem(context, est);
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.fileText, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('아직 저장된 견적이 없습니다.', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEstimateItem(BuildContext context, dynamic est) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EstimateDetailScreen(estimate: est),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  est.date,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: est.status == '수리완료'
                        ? Colors.blueAccent.withOpacity(0.1)
                        : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    est.status,
                    style: TextStyle(
                      color: est.status == '수리완료'
                          ? Colors.blueAccent
                          : Colors.amber[800],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (est.imageUrl != null)
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        est.imageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 20,
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.image,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        est.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        est.price,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
