import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shop_provider.dart';
import '../widgets/service_center_item.dart';
import '../widgets/custom_search_bar.dart';
import '../utils/consumer_design.dart';

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
  String _searchQuery = '';

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
        final filteredShops = allShops.where((shop) {
          final query = _searchQuery.toLowerCase();
          return shop.name.toLowerCase().contains(query) ||
              shop.address.toLowerCase().contains(query);
        }).toList();
        final hasMore = filteredShops.length > _initialShowLimit;

        // 표시할 리스트 결정
        final shopsToShow = (_showAll || !hasMore)
            ? filteredShops
            : filteredShops.take(_initialShowLimit).toList();

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('내 근처 정비소 (10km)', style: ConsumerTypography.h1),
                      const SizedBox(height: 4),
                      Text(
                        filteredShops.isEmpty && !shopProvider.isLoading
                            ? '검색된 정비소가 없습니다.'
                            : '총 ${filteredShops.length}개의 정비소가 검색되었습니다.',
                        style: ConsumerTypography.tag,
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () {
                      _searchQuery = '';
                      shopProvider.fetchNearbyShops();
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: shopProvider.isLoading && allShops.isEmpty
                  ? _buildLoadingView()
                  : filteredShops.isEmpty
                  ? _buildEmptyView(
                      shopProvider.error,
                      isSearch: _searchQuery.isNotEmpty,
                    )
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

  Widget _buildEmptyView(String? error, {bool isSearch = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearch ? Icons.search_off : Icons.location_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              error ?? (isSearch ? '검색 결과가 없습니다.' : '10km 이내에 정비소가 없습니다.'),
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
