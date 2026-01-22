import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geoflutterfire_plus/geoflutterfire_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lucide_icons/lucide_icons.dart';

// [모델 클래스: ServiceCenter]
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
  static const double _searchRadiusInKm = 10.0; // 실서비스용 10km 설정

  Stream<List<ServiceCenter>>? _shopsStream;
  String _statusMessage = '위치 권한 및 GPS를 확인 중입니다...';

  @override
  void initState() {
    super.initState();
    _initializeLocationAndQuery();
  }

  Future<void> _initializeLocationAndQuery() async {
    try {
      // 위치 권한 확인 및 요청
      await _determinePosition();

      // 1. 위치 확보 (속도 최적화 버전)
      Position? position = await Geolocator.getLastKnownPosition();

      // 마지막 위치가 없으면 정밀도를 낮춰서 빠르게 현재 위치 획득
      position ??= await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5),
        ),
      );

      if (position == null) {
        throw Exception('위치 정보를 가져올 수 없습니다.');
      }

      final double myLat = position.latitude;
      final double myLng = position.longitude;

      if (mounted) {
        setState(() {
          _statusMessage = '주변 정비소를 탐색 중입니다...';
        });
      }

      // 2. 쿼리 및 스트림 설정 (최적화 버전)
      final GeoCollectionReference<Map<String, dynamic>> geoCollectionRef =
          GeoCollectionReference<Map<String, dynamic>>(
            FirebaseFirestore.instance.collection('service_centers'),
          );

      final GeoFirePoint center = GeoFirePoint(GeoPoint(myLat, myLng));

      final stream = geoCollectionRef
          .subscribeWithin(
            center: center,
            radiusInKm: _searchRadiusInKm,
            field: 'position', // 중첩 필드이므로 'position' 상위 맵 지정
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
                    myLat,
                    myLng,
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
          _statusMessage = '정보를 가져오는데 실패했습니다.\n$e';
        });
      }
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('위치 서비스가 꺼져 있습니다.');

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

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '내 근처 정비소 (10km)',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _initializeLocationAndQuery,
              ),
            ],
          ),
        ),
        // 현재 위치 표시 바 제거
        Expanded(
          child: _shopsStream == null
              ? _buildLoadingView()
              : StreamBuilder<List<ServiceCenter>>(
                  stream: _shopsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('오류 발생: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingView();
                    }

                    final shops = snapshot.data ?? [];

                    if (shops.isEmpty) {
                      return const Center(child: Text('10km 이내에 정비소가 없습니다.'));
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

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItem(BuildContext context, ServiceCenter shop) {
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
        ],
      ),
    );
  }
}
