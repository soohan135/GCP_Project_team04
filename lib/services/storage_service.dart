import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 이미지 압축 (파일 크기 50-70% 감소)
  Future<File?> _compressImage(XFile image) async {
    try {
      final imageBytes = await image.readAsBytes();
      final decodedImage = img.decodeImage(imageBytes);

      if (decodedImage == null) return null;

      // 최대 너비 1200px로 리사이징하고 80% 품질로 압축
      final resized = img.copyResize(decodedImage, width: 1200);
      final compressed = File(image.path)
        ..writeAsBytesSync(img.encodeJpg(resized, quality: 80));

      return compressed;
    } catch (e) {
      print('Image compression error: $e');
      return null;
    }
  }

  Future<String?> uploadCrashedCarPicture(XFile image) async {
    try {
      // 현재 사용자 확인
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // 1. 이미지 압축 (업로드 시간 단축)
      final compressedImage = await _compressImage(image);
      final fileToUpload = compressedImage ?? File(image.path);

      // uid와 날짜 문자열 생성
      final uid = user.uid;
      final now = DateTime.now();
      final dateString = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      // 카운터 문서 ID
      final counterDocId = '${uid}_${dateString}';

      // 트랜잭션으로 카운터 증가
      final counterRef = _firestore.collection('upload_counters').doc(counterDocId);
      int sequenceNumber = 1;
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(counterRef);
        if (snapshot.exists) {
          final currentCount = snapshot.data()?['count'] as int? ?? 0;
          sequenceNumber = currentCount + 1;
          transaction.update(counterRef, {'count': sequenceNumber});
        } else {
          sequenceNumber = 1;
          transaction.set(counterRef, {'count': sequenceNumber});
        }
      });

      // 시퀀스 번호를 두 자리로 포맷
      final sequenceString = sequenceNumber.toString().padLeft(2, '0');

      // 파일 이름 생성: uid_생성일_생성번호
      final fileName = '${uid}_${dateString}_${sequenceString}';

      // Firebase Storage 참조
      final ref = _storage.ref().child('crashed_car_picture/$fileName.jpg');

      // 2. 메타데이터 설정 (캐싱 최적화 및 uid 추가)
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'uid': uid,
        },
        cacheControl: 'public, max-age=2592000', // 30일 캐싱
      );

      // 3. 파일 업로드
      await ref.putFile(fileToUpload, metadata);

      // 4. URL 미리 구성 (API 호출 제거로 속도 개선)
      final downloadUrl = 'https://firebasestorage.googleapis.com/v0/b/'
          '${_storage.bucket}/o/crashed_car_picture%2F$fileName.jpg'
          '?alt=media';

      // 5. Firestore에 estimate_history 서브컬렉션에 문서 추가
      await _firestore.collection('users').doc(uid).collection('estimate_history').doc('$fileName.jpg').set({
        'createdAt': now.toIso8601String(),
        'estimateCost': null,
        'imageUploadUrl': null,
        'imageDamageUrl': null,
        'imageDamagePartUrl': null,
        'note': null,
      });

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}