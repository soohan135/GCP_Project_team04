import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';

class NearbyShopsScreen extends StatefulWidget {
  const NearbyShopsScreen({super.key});

  @override
  State<NearbyShopsScreen> createState() => _NearbyShopsScreenState();
}

class _NearbyShopsScreenState extends State<NearbyShopsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _shops = [];

  @override
  void initState() {
    super.initState();
    _fetchNearbyShops();
  }

  Future<void> _fetchNearbyShops() async {
    setState(() => _isLoading = true);

    try {
      // Mock location and Firebase call
      // In real scenario: LocationPermission permission = await Geolocator.requestPermission();
      // Position position = await Geolocator.getCurrentPosition();

      await Future.delayed(const Duration(seconds: 1));

      _shops = [
        {
          'name': '현대 블루핸즈 강남점',
          'address': '서울특별시 강남구 테헤란로 123',
          'distance': '1.2km',
          'rating': 4.8,
          'isOpen': true,
        },
        {
          'name': '기아 오토큐 서초점',
          'address': '서울특별시 서초구 서초대로 456',
          'distance': '2.5km',
          'rating': 4.5,
          'isOpen': true,
        },
        {
          'name': '스피드메이트 송파센터',
          'address': '서울특별시 송파구 올림픽로 789',
          'distance': '3.1km',
          'rating': 4.2,
          'isOpen': false,
        },
        {
          'name': '마이클 정비소 삼전점',
          'address': '서울특별시 송파구 삼전로 101',
          'distance': '4.0km',
          'rating': 4.9,
          'isOpen': true,
        },
        {
          'name': '공임나라 잠실점',
          'address': '서울특별시 송파구 가락동 202',
          'distance': '5.2km',
          'rating': 4.0,
          'isOpen': true,
        },
      ];
    } catch (e) {
      debugPrint('Error fetching shops: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            '내 근처 정비소',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        if (_isLoading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _shops.length,
              itemBuilder: (context, index) {
                final shop = _shops[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          LucideIcons.mapPin,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shop['name'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              shop['address'],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  LucideIcons.star,
                                  size: 14,
                                  color: Colors.amber,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  shop['rating'].toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  shop['distance'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: shop['isOpen']
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          shop['isOpen'] ? '영업중' : '영업종료',
                          style: TextStyle(
                            color: shop['isOpen'] ? Colors.green : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
