import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String userName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? imageUrl;

  Review({
    required this.id,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.imageUrl,
  });

  factory Review.fromMap(Map<String, dynamic> map, String docId) {
    return Review(
      id: docId,
      userName: map['userName'] ?? '익명',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
    };
  }
}
