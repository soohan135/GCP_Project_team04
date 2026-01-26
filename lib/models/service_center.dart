import 'package:cloud_firestore/cloud_firestore.dart';
import 'review.dart';

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
  final int reviewCount;
  final List<Review> latestReviews;

  ServiceCenter({
    required this.id,
    required this.name,
    required this.address,
    required this.tel,
    required this.latitude,
    required this.longitude,
    required this.distanceFromUser,
    this.rating = 0.0,
    this.isOpen = true,
    this.reviewCount = 0,
    List<Review>? latestReviews,
  }) : latestReviews = latestReviews ?? [];

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
      rating: (data['rating'] ?? 0.0).toDouble(),
      isOpen: data['isOpen'] ?? true,
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  ServiceCenter copyWith({
    List<Review>? latestReviews,
    double? rating,
    int? reviewCount,
  }) {
    return ServiceCenter(
      id: id,
      name: name,
      address: address,
      tel: tel,
      latitude: latitude,
      longitude: longitude,
      distanceFromUser: distanceFromUser,
      rating: rating ?? this.rating,
      isOpen: isOpen,
      reviewCount: reviewCount ?? this.reviewCount,
      latestReviews: latestReviews ?? this.latestReviews,
    );
  }
}
