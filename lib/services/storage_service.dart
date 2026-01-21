import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> uploadCrashedCarPicture(XFile image) async {
    try {
      // 현재 사용자 확인
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // 파일 이름 생성: uid_YYYYMMDD
      final uid = user.uid;
      final now = DateTime.now();
      final dateString = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
      final fileName = '${uid}_$dateString';

      // Firebase Storage 참조
      final ref = _storage.ref().child('crashed_car_picture/$fileName.jpg');

      // 파일 업로드
      await ref.putFile(File(image.path));

      // 업로드된 파일의 URL 반환 (필요시)
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}