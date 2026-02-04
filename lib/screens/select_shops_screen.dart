import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/estimate_provider.dart';
import '../providers/shop_provider.dart';
import '../models/service_center.dart';
import '../widgets/custom_search_bar.dart';
import '../utils/consumer_design.dart';

class SelectShopsScreen extends StatefulWidget {
  final Estimate estimate;

  const SelectShopsScreen({super.key, required this.estimate});

  @override
  State<SelectShopsScreen> createState() => _SelectShopsScreenState();
}

class _SelectShopsScreenState extends State<SelectShopsScreen> {
  final Set<String> _selectedShopIds = {};
  final TextEditingController _shopCountController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _shopCountController.dispose();
    super.dispose();
  }

  void _sendRequest() async {
    final estimateProvider = context.read<EstimateProvider>();
    final shopProvider = context.read<ShopProvider>();
    List<ServiceCenter> shopsToSend;

    if (_selectedShopIds.isNotEmpty) {
      shopsToSend = shopProvider.shops
          .where((shop) => _selectedShopIds.contains(shop.id))
          .toList();
    } else if (_shopCountController.text.isNotEmpty) {
      final count = int.tryParse(_shopCountController.text);
      if (count != null && count > 0) {
        shopsToSend = shopProvider.shops.take(count).toList();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('유효한 숫자를 입력해주세요.')));
        return;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('정비소를 선택하거나 보낼 정비소 수를 입력해주세요.')),
      );
      return;
    }

    if (shopsToSend.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('요청을 보낼 정비소가 없습니다.')));
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${shopsToSend.length}개의 정비소에 수리 요청을 전송 중입니다...'),
        ),
      );

      await estimateProvider.sendEstimateToNearbyShops(
        estimate: widget.estimate,
        shops: shopsToSend,
      );

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${shopsToSend.length}개의 정비소에 수리 요청을 성공적으로 보냈습니다.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('요청 전송 중 오류가 발생했습니다: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopProvider = context.watch<ShopProvider>();
    final allShops = shopProvider.shops;
    final filteredShops = allShops.where((shop) {
      final query = _searchQuery.toLowerCase();
      return shop.name.toLowerCase().contains(query) ||
          shop.address.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: ConsumerColor.brand50,
      appBar: AppBar(
        title: Text('정비소 선택', style: ConsumerTypography.h2),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _shopCountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '상위 N개 정비소에 보내기',
                hintText: '숫자 입력...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
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
          const Divider(),
          Expanded(
            child: filteredShops.isEmpty
                ? const Center(
                    child: Text(
                      '검색 결과가 없습니다.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredShops.length,
                    itemBuilder: (context, index) {
                      final shop = filteredShops[index];
                      final isSelected = _selectedShopIds.contains(shop.id);

                      return CheckboxListTile(
                        title: Text(shop.name),
                        subtitle: Text(shop.address),
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedShopIds.add(shop.id);
                            } else {
                              _selectedShopIds.remove(shop.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 32,
          top: 16,
        ),
        child: ElevatedButton(
          onPressed: _sendRequest,
          style: ElevatedButton.styleFrom(
            backgroundColor: ConsumerColor.brand500,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: const Text(
            '선택한 정비소에 요청 보내기',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
