import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 채팅방 가져오기 또는 생성하기
  Future<String> getOrCreateChatRoom(
    String otherUserId, {
    String? estimateId,
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
      });
    } else if (estimateId != null) {
      // 기존 채팅방이 있으면 견적 ID 업데이트 (최신 상담 맥락 유지)
      await _firestore.collection('chat_rooms').doc(roomId).update({
        'estimateId': estimateId,
      });
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
}
