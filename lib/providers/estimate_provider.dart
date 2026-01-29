import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Estimate {
  final String id;
  final String title;
  final String date;
  final String damage;
  final String price;
  final String status;
  final String? imageUrl;
  final List<String> recommendations;
  final String? realPrice;

  Estimate({
    required this.id,
    required this.title,
    required this.date,
    required this.damage,
    required this.price,
    required this.status,
    this.imageUrl,
    required this.recommendations,
    this.realPrice,
  });
}

class EstimateProvider with ChangeNotifier {
  List<Estimate> _estimates = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  List<Estimate> get estimates => _estimates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void initialize() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _subscribeToEstimates(user.uid);
      } else {
        _subscription?.cancel();
        _estimates = [];
        notifyListeners();
      }
    });
  }

  void _subscribeToEstimates(String uid) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _subscription?.cancel();
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('estimates')
        .snapshots()
        .listen(
          (snapshot) {
            _estimates = snapshot.docs.map((doc) {
              final data = doc.data();
              return Estimate(
                id: doc.id,
                title: data['title'] ?? data['damage'] ?? '알 수 없음',
                date: data['date'] ?? '알 수 없음',
                damage: data['damage'] ?? '알 수 없음',
                price: data['estimatedPrice'] ?? '알 수 없음',
                status: data['realPrice'] != null ? '수리 완료' : '저장됨',
                imageUrl:
                    data['imageUrl'] ??
                    data['analyzedImageUrl'] ??
                    data['imageUploadUrl'],
                recommendations: List<String>.from(
                  data['recommendations'] ?? [],
                ),
                realPrice: data['realPrice'],
              );
            }).toList();

            _isLoading = false;
            notifyListeners();
          },
          onError: (e) {
            _error = e.toString();
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  Future<void> updateRealPrice(String estimateId, String realPrice) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('estimates')
          .doc(estimateId)
          .update({'realPrice': realPrice});
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendEstimateToNearbyShops({
    required Estimate estimate,
    required List<dynamic> shops,
    String? userRequest,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다.');

    final batch = FirebaseFirestore.instance.batch();

    // 상위 10개 정비소 선택
    final targetShops = shops.take(10).toList();

    for (var shop in targetShops) {
      final ref = FirebaseFirestore.instance
          .collection('service_centers')
          .doc(shop.id)
          .collection('receive_estimate')
          .doc();

      batch.set(ref, {
        'imageUrl': estimate.imageUrl,
        'damageType': estimate.damage,
        'damagedParts': estimate.recommendations,
        'userId': user.uid,
        'userEmail': user.email,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
        'estimateId': estimate.id,
        'userRequest': userRequest,
      });
    }

    await batch.commit();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
