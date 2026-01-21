import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';

// [모델 클래스: ServiceCenter] - (변경 없음)
class ServiceCenter {
  final String id;
  final String name;
  final String address;
  final String tel;
  final double latitude;
  final double longitude;
  final double distanceFromUser;
  final double rating;
  final bool isOpen;

  ServiceCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.tel,
    required this.latitude,
    required this.longitude,
    required this.distanceFromUser,
    this.rating = 4.5,
    this.isOpen = true,
  });

  factory ServiceCenter.fromGeoDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
    double distanceInKm,
  ) {
    final data = document.data()!;
    final positionMap = data['position'] as Map<String, dynamic>? ?? {};
    final geoPoint = positionMap['geopoint'] as GeoPoint?;

    return ServiceCenter(
      id: document.id,
      name: data['name'] ?? '이름 없음',
      address: data['address'] ?? '주소 정보 없음',
      tel: data['tel'] ?? '',
      latitude: geoPoint?.latitude ?? 0.0,
      longitude: geoPoint?.longitude ?? 0.0,
      distanceFromUser: distanceInKm,
      rating: 4.5,
      isOpen: true,
    );
  }
}

class NearbyShopsScreen extends StatefulWidget {
  const NearbyShopsScreen({super.key});

  @override
  State<NearbyShopsScreen> createState() => _NearbyShopsScreenState();
}

class _NearbyShopsScreenState extends State<NearbyShopsScreen> {
  static const double _searchRadiusInKm = 100.0;

  Stream<List<ServiceCenter>>? _shopsStream;

  // [추가] 로딩 상태를 알려줄 메시지 변수
  String _statusMessage = '위치 권한 및 GPS를 확인 중입니다...';

  @override
  void initState() {
    super.initState();
    _initializeLocationAndQuery();
  }

  Future<void> _initializeLocationAndQuery() async {
    try {
      // 1. 위치 확보 시도
      final position = await _determinePosition();

      /////////////////////////////////////
      debugPrint('📍 현재 내 위치: ${position.latitude}, ${position.longitude}');

      // DB에 있는 '달구지카크리닉(일산)'의 좌표 (아까 사진에 있던 값)
      double targetLat = 37.6441906341;
      double targetLng = 126.7823187377;

      // 내 위치와 DB 데이터 사이의 거리 계산 (km 단위)
      double distInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLng,
      );
      double distInKm = distInMeters / 1000;

      debugPrint('📏 DB 데이터(일산)까지의 거리: $distInKm km');
      //////////////////////////////

      // 2. 위치 확보 성공 시 UI 업데이트 (로딩 메시지 변경)
      if (mounted) {
        setState(() {
          // 소수점 4자리까지만 보여주어 깔끔하게 표시
          _statusMessage =
              '현재 위치 확인 완료!\n'
              '(${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)})\n\n'
              '주변 10km 반경 정비소를 탐색 중입니다...';
        });
      }

      // 3. 쿼리 및 스트림 설정
      final GeoCollectionReference<Map<String, dynamic>> geoCollectionRef =
          GeoCollectionReference<Map<String, dynamic>>(
            FirebaseFirestore.instance.collection('service_centers'),
          );

      final GeoFirePoint center = GeoFirePoint(
        GeoPoint(position.latitude, position.longitude),
      );

      final stream = geoCollectionRef
          .subscribeWithin(
            center: center,
            radiusInKm: _searchRadiusInKm,
            field: 'position.geohash',
            geopointFrom: (data) =>
                (data['position'] as Map<String, dynamic>)['geopoint']
                    as GeoPoint,
            strictMode: true,
          )
          .map((snapshots) {
            final List<ServiceCenter> shops = snapshots
                .map((shot) {
                  final data = shot.data();
                  if (data == null) return null;

                  final positionMap = data['position'] as Map<String, dynamic>?;
                  if (positionMap == null) return null;

                  final geoPoint = positionMap['geopoint'] as GeoPoint?;
                  if (geoPoint == null) return null;

                  final distInMeters = Geolocator.distanceBetween(
                    position.latitude,
                    position.longitude,
                    geoPoint.latitude,
                    geoPoint.longitude,
                  );
                  final dist = distInMeters / 1000;

                  return ServiceCenter.fromGeoDocument(shot, dist);
                })
                .whereType<ServiceCenter>()
                .toList();

            // 거리순 정렬
            shops.sort(
              (a, b) => a.distanceFromUser.compareTo(b.distanceFromUser),
            );

            return shops;
          });

      if (mounted) {
        setState(() {
          _shopsStream = stream;
        });
      }
    } catch (e) {
      debugPrint('오류 발생: $e');
      if (mounted) {
        setState(() {
          _statusMessage = '위치 정보를 가져오는데 실패했습니다.\n$e';
        });
      }
    }
  }

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
            '내 근처 정비소 (10km)',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          // _shopsStream이 준비되지 않았으면 로딩 화면 표시
          child: _shopsStream == null
              ? _buildLoadingView() // [분리된 로딩 위젯]
              : StreamBuilder<List<ServiceCenter>>(
                  stream: _shopsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('오류 발생: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // 스트림 연결 중에도 위치 정보는 확보된 상태이므로 로딩 뷰 표시
                      return _buildLoadingView();
                    }

                    final shops = snapshot.data ?? [];

                    if (shops.isEmpty) {
                      return const Center(child: Text('근처에 정비소가 없습니다.'));
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      itemCount: shops.length,
                      itemBuilder: (context, index) {
                        return _buildShopItem(context, shops[index]);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // [UI 추가] 로딩 중일 때 보여줄 위젯 (위치 정보 텍스트 포함)
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            _statusMessage, // 상태에 따라 변경되는 메시지
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5, // 줄간격
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItem(BuildContext context, ServiceCenter shop) {
    // (기존 아이템 UI 코드와 동일)
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
            child: const Icon(LucideIcons.mapPin, color: Colors.blueAccent),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shop.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  shop.address,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                if (shop.tel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    shop.tel,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(
                      shop.rating.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${shop.distanceFromUser.toStringAsFixed(1)}km',
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: shop.isOpen
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              shop.isOpen ? '영업중' : '영업종료',
              style: TextStyle(
                color: shop.isOpen ? Colors.green : Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
