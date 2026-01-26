import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/service_center_item.dart';

class NearbyShopsScreen extends StatefulWidget {
  const NearbyShopsScreen({super.key});

  @override
  State<NearbyShopsScreen> createState() => _NearbyShopsScreenState();
}

class _NearbyShopsScreenState extends State<NearbyShopsScreen> {
  bool _showAll = false;
  static const int _initialShowLimit = 8;
  final ScrollController _scrollController = ScrollController();
  String? _expandedShopId;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (context, shopProvider, child) {
        final allShops = shopProvider.shops;
        final hasMore = allShops.length > _initialShowLimit;

        // 표시할 리스트 결정
        final shopsToShow = (_showAll || !hasMore)
            ? allShops
            : allShops.take(_initialShowLimit).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '내 근처 정비소 (10km)',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        allShops.isEmpty && !shopProvider.isLoading
                            ? '검색된 정비소가 없습니다.'
                            : '총 ${allShops.length}개의 정비소가 검색되었습니다.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => shopProvider.fetchNearbyShops(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: shopProvider.isLoading && allShops.isEmpty
                  ? _buildLoadingView()
                  : allShops.isEmpty
                  ? _buildEmptyView(shopProvider.error)
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
                        itemCount:
                            shopsToShow.length + (hasMore && !_showAll ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == shopsToShow.length) {
                            return _buildShowMoreButton();
                          }
                          final shop = shopsToShow[index];
                          return ServiceCenterItem(
                            shop: shop,
                            isExpanded: _expandedShopId == shop.id,
                            onTap: () {
                              setState(() {
                                _expandedShopId = _expandedShopId == shop.id
                                    ? null
                                    : shop.id;
                              });
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 24),
          Text(
            '주변 정비소를 탐색 중입니다...',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView(String? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              error ?? '10km 이내에 정비소가 없습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShowMoreButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 32.0),
      child: Center(
        child: InkWell(
          onTap: () => setState(() => _showAll = true),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add, size: 18, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text(
                  '정비소 더보기',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
