import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class NearbyShopsScreen extends StatefulWidget {
  const NearbyShopsScreen({super.key});

  @override
  State<NearbyShopsScreen> createState() => _NearbyShopsScreenState();
}

class _NearbyShopsScreenState extends State<NearbyShopsScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _shops = [];
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchNearbyShops();
  }

  Future<void> _fetchNearbyShops() async {
    setState(() => _isLoading = true);

    try {
      // 1. 내 현재 위치 확보
      Position myPos = await _determinePosition();

      // 2. Firestore에서 데이터 조회
      QuerySnapshot snapshot = await _db.collection('service_centers').get();
      debugPrint(
        'Firestore fetch success. Docs count: ${snapshot.docs.length}',
      );

      List<Map<String, dynamic>> centers = [];

      // 3. 데이터 파싱 및 거리 계산
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // [구조 수정] 이미지에 따르면 geopoint는 'position' 맵 필드 안에 있음
        // {
        //   "name": "...",
        //   "position": {
        //     "geopoint": GeoPoint(lat, lng),
        //     "geohash": "..."
        //   }
        // }

        var positionMap = data['position'];
        // position 필드가 없거나 Map이 아니면 건너뜀
        if (positionMap == null || positionMap is! Map) {
          debugPrint(
            'Document ${doc.id} has no position field or invalid type',
          );
          continue;
        }

        var geoData = positionMap['geopoint'];
        if (geoData == null) {
          debugPrint('Document ${doc.id} has no geopoint in position');
          continue;
        }

        double centerLat = 0.0;
        double centerLng = 0.0;

        // 데이터 구조 호환성 처리 (GeoPoint 또는 List<double>)
        if (geoData is GeoPoint) {
          centerLat = geoData.latitude;
          centerLng = geoData.longitude;
        } else if (geoData is List && geoData.length >= 2) {
          centerLat = (geoData[0] as num).toDouble();
          centerLng = (geoData[1] as num).toDouble();
        } else if (geoData is Map &&
            geoData.containsKey('latitude') &&
            geoData.containsKey('longitude')) {
          // 일부 경우를 대비한 추가 방어 (Map으로 오는 경우)
          centerLat = (geoData['latitude'] as num).toDouble();
          centerLng = (geoData['longitude'] as num).toDouble();
        } else {
          debugPrint(
            'Document ${doc.id} has invalid geopoint format: $geoData',
          );
          continue;
        }

        // 거리 계산 (미터 단위)
        double distanceInMeters = Geolocator.distanceBetween(
          myPos.latitude,
          myPos.longitude,
          centerLat,
          centerLng,
        );

        // UI 데이터 포맷으로 변환
        centers.add({
          'name': data['name'] ?? '이름 없음',
          'address': data['address'] ?? '주소 정보 없음',
          // 거리 포맷팅 (km 단위, 소수점 1자리)
          'distance': '${(distanceInMeters / 1000).toStringAsFixed(1)}km',
          'distanceVal': distanceInMeters, // 정렬을 위한 숫자 값
          // 평점과 영업여부는 Firestore에 없으므로 기본값 설정 (추후 연동 필요)
          'rating': 4.5,
          'isOpen': true,
        });
      }

      // 4. 거리순 정렬 (오름차순)
      centers.sort(
        (a, b) =>
            (a['distanceVal'] as double).compareTo(b['distanceVal'] as double),
      );

      _shops = centers;
    } catch (e) {
      debugPrint('Error fetching shops: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('데이터 로드 실패: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 위치 권한 확인 및 현재 위치 반환
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('위치 서비스가 꺼져 있습니다.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('위치 권한이 영구적으로 거부되었습니다.');
    }

    return await Geolocator.getCurrentPosition();
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
        else if (_shops.isEmpty)
          const Expanded(child: Center(child: Text('근처에 정비소가 없습니다.')))
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
