import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/estimate_provider.dart';
import 'estimate_detail_screen.dart';
import '../widgets/custom_search_bar.dart';
import '../utils/consumer_design.dart';

class EstimatePreviewScreen extends StatefulWidget {
  const EstimatePreviewScreen({super.key});

  @override
  State<EstimatePreviewScreen> createState() => _EstimatePreviewScreenState();
}

class _EstimatePreviewScreenState extends State<EstimatePreviewScreen> {
  final ScrollController _scrollController = ScrollController();
  String _searchQuery = '';

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EstimateProvider>(
      builder: (context, provider, child) {
        final allEstimates = provider.estimates;
        final filteredEstimates = allEstimates.where((est) {
          final query = _searchQuery.toLowerCase();
          return est.title.toLowerCase().contains(query) ||
              est.status.toLowerCase().contains(query);
        }).toList();

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
                  Text('견적 미리보기', style: ConsumerTypography.h1),
                  if (filteredEstimates.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '총 ${filteredEstimates.length}개의 저장된 견적이 있습니다.',
                      style: ConsumerTypography.tag,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: provider.isLoading && allEstimates.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filteredEstimates.isEmpty
                  ? _buildEmptyView(isSearch: _searchQuery.isNotEmpty)
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
                        itemCount: filteredEstimates.length,
                        itemBuilder: (context, index) {
                          final est = filteredEstimates[index];
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

  Widget _buildEmptyView({bool isSearch = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSearch ? Icons.search_off : LucideIcons.fileText,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            isSearch ? '검색 결과가 없습니다.' : '아직 저장된 견적이 없습니다.',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimateItem(BuildContext context, Estimate est) {
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: ConsumerColor.slate100),
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
                    color: est.status == '수리 완료'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    est.status,
                    style: TextStyle(
                      color: est.status == '수리 완료'
                          ? Colors.green
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
                        style: ConsumerTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ConsumerColor.slate800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (est.realPrice != null) ...[
                        Text(
                          '예상: ${est.price}',
                          style: ConsumerTypography.bodySmall.copyWith(
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          est.realPrice!,
                          style: ConsumerTypography.h2.copyWith(
                            color: Colors.green,
                          ),
                        ),
                      ] else ...[
                        Text(
                          est.price,
                          style: ConsumerTypography.h2.copyWith(
                            color: ConsumerColor.brand600,
                          ),
                        ),
                      ],
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
