import 'package:cloud_firestore/cloud_firestore.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 일정 추가
  /// [shopId]: 정비소 ID
  /// [date]: 수리 날짜 (날짜 단위로 저장)
  /// [title]: 일정 제목
  /// [description]: 일정 상세 내용
  /// [customerEmail]: 고객 이메일 (또는 식별자)
  Future<void> addSchedule({
    required String shopId,
    required DateTime date,
    required String title,
    required String description,
    required String customerEmail,
    int? duration, // 일 단위 예상 소요 기간
  }) async {
    try {
      // 시간을 00:00:00으로 정규화 (선택 사항이나 캘린더 매칭을 위해 권장)
      final normalizedDate = DateTime(date.year, date.month, date.day);

      await _firestore
          .collection('service_centers')
          .doc(shopId)
          .collection('schedules')
          .add({
            'date': Timestamp.fromDate(normalizedDate),
            'title': title,
            'description': description,
            'customerEmail': customerEmail,
            'duration': duration,
            'createdAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error adding schedule: $e');
      rethrow;
    }
  }

  /// 일정 스트림 가져오기 (월별 가져오기 등은 쿼리로 최적화 가능하지만, 일단 전체/기간으로)
  /// 여기서는 해당 정비소의 모든 일정을 스트림으로 반환
  Stream<List<Map<String, dynamic>>> getSchedules(String shopId) {
    return _firestore
        .collection('service_centers')
        .doc(shopId)
        .collection('schedules')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            // Timestamp to DateTime conversion logic handled here or in UI model
            if (data['date'] is Timestamp) {
              data['date'] = (data['date'] as Timestamp).toDate();
            }
            return data;
          }).toList();
        });
  }
}
