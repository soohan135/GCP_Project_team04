import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class CarCenterService {
  // Firestore 인스턴스
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// [핵심 기능] 내 위치를 기준으로 정비소(Car Center) 목록을 가져와서 거리순으로 정렬
  Future<List<Map<String, dynamic>>> getNearbyCenters() async {
    try {
      // 1. 내 현재 위치 확보
      Position myPos = await _determinePosition();

      // 2. Firestore에서 데이터 조회
      QuerySnapshot snapshot = await _db.collection('service_centers').get();

      List<Map<String, dynamic>> centers = [];

      // 3. 데이터 파싱 및 거리 계산
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;

        // [방어 코드] 필수 데이터(좌표) 체크
        if (data['geopoint'] == null) {
          continue;
        }

        // 데이터 구조: geopoint는 [위도, 경도] 리스트
        List<dynamic> geoPoint = data['geopoint'];
        if (geoPoint.length < 2) continue;

        double centerLat = (geoPoint[0] as num).toDouble(); // 위도
        double centerLng = (geoPoint[1] as num).toDouble(); // 경도

        // 거리 계산 (미터 단위)
        double distanceInMeters = Geolocator.distanceBetween(
          myPos.latitude,
          myPos.longitude,
          centerLat,
          centerLng,
        );

        // UI용 데이터 가공
        centers.add({
          'id': doc.id,
          'name': data['name'] ?? '이름 없음',
          'address': data['address'] ?? '주소 정보 없음',
          'tel': data['tel'] ?? '',
          'lat': centerLat,
          'lng': centerLng,
          'distance': distanceInMeters,
        });
      }

      // 4. 거리순 정렬 (오름차순)
      centers.sort((a, b) => a['distance'].compareTo(b['distance']));

      return centers;

    } catch (e) {
      print('Car Center 데이터 로드 중 오류 발생: $e');
      rethrow;
    }
  }

  /// [내부 함수] 위치 권한 확인 및 현재 위치 반환
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
}