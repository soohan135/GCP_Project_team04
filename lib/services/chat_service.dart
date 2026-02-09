import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../providers/estimate_provider.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 채팅방 가져오기 또는 생성하기
  Future<String> getOrCreateChatRoom(
    String otherUserId, {
    String? estimateId,
    String? shopName,
    String? consumerId,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw Exception('로그인이 필요합니다.');

    // 참여자 ID 정렬 (일관된 roomId 생성을 위함)
    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    String roomId = ids.join('_');

    final roomDoc = await _firestore.collection('chat_rooms').doc(roomId).get();

    if (!roomDoc.exists) {
      // 채팅방이 없으면 새로 생성
      await _firestore.collection('chat_rooms').doc(roomId).set({
        'participants': ids,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageAt': FieldValue.serverTimestamp(),
        if (estimateId != null) 'estimateId': estimateId,
        if (shopName != null) 'shopName': shopName,
        if (consumerId != null) 'consumerId': consumerId,
      });
    } else {
      // 기존 채팅방이 있으면 정보 업데이트
      final updateData = <String, dynamic>{};
      if (estimateId != null) updateData['estimateId'] = estimateId;
      if (shopName != null) updateData['shopName'] = shopName;
      if (consumerId != null) updateData['consumerId'] = consumerId;

      if (updateData.isNotEmpty) {
        await _firestore
            .collection('chat_rooms')
            .doc(roomId)
            .update(updateData);
      }
    }

    return roomId;
  }

  // 메시지 전송
  Future<void> sendMessage(String roomId, String text) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    final messageData = {
      'senderId': currentUserId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'readBy': [currentUserId],
    };

    final batch = _firestore.batch();

    // 1. 메시지 하위 컬렉션에 추가
    final messageRef = _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();
    batch.set(messageRef, messageData);

    // 2. 채팅방 메타데이터 업데이트
    final roomRef = _firestore.collection('chat_rooms').doc(roomId);
    batch.update(roomRef, {
      'lastMessage': text,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageSenderId': currentUserId,
    });

    await batch.commit();
  }

  // 채팅방 리스트 스트림
  Stream<QuerySnapshot> getChatRooms({String? userId}) {
    final effectiveUserId = userId ?? _auth.currentUser?.uid;
    return _firestore
        .collection('chat_rooms')
        .where('participants', arrayContains: effectiveUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  // 메시지 내역 스트림
  Stream<QuerySnapshot> getMessages(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get the other participant's user data
  Future<AppUser?> getOtherParticipantUser(
    List<dynamic> participants,
    String currentUserId,
  ) async {
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => null,
    );
    if (otherUserId != null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();
      if (userDoc.exists) {
        return AppUser.fromFirestore(userDoc);
      }
    }
    return null;
  }

  // Get estimate details
  Future<Estimate?> getEstimateDetails(
    String estimateId,
    String consumerId,
  ) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(consumerId)
          .collection('estimates')
          .doc(estimateId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
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
          recommendations: List<String>.from(data['recommendations'] ?? []),
          realPrice: data['realPrice'],
        );
      }
    } catch (e) {
      print('Error getting estimate details: $e');
    }
    return null;
  }
}
