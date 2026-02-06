import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { consumer, mechanic, none }

class AppUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final UserRole role;
  final String? serviceCenterId;
  final String? fcmToken;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.role = UserRole.none,
    this.serviceCenterId,
    this.fcmToken,
    this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    UserRole role = UserRole.none;
    final roleStr = data['role'] as String?;
    if (roleStr == 'consumer') {
      role = UserRole.consumer;
    } else if (roleStr == 'mechanic') {
      role = UserRole.mechanic;
    }

    return AppUser(
      uid: doc.id,
      email: data['email'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      role: role,
      serviceCenterId: data['serviceCenterId'],
      fcmToken: data['fcmToken'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'role': role.name,
      'serviceCenterId': serviceCenterId,
      'fcmToken': fcmToken,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  AppUser copyWith({
    UserRole? role,
    String? serviceCenterId,
    String? fcmToken,
  }) {
    return AppUser(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      role: role ?? this.role,
      serviceCenterId: serviceCenterId ?? this.serviceCenterId,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
    );
  }
}
