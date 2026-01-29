import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // TODO: Replace with your actual AI Service URL
  static const String _aiServiceUrl = 'https://analyze-crashed-car-2-zujfj3v5ta-du.a.run.app';

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

  /// AI 서비스에 이미지 업로드 및 분석 요청
  Future<Map<String, dynamic>?> _uploadToAiService(File imageFile) async {
    try {
      if (_aiServiceUrl.contains('YOUR_AI_SERVICE_URL_HERE')) {
        print('AI Service URL is not configured.');
        return null;
      }

      final request = http.MultipartRequest('POST', Uri.parse(_aiServiceUrl));
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));
      request.fields['car_model'] = 'unknown';
      // 필요한 헤더 추가 (예: Authorization)
      // request.headers['Authorization'] = 'Bearer YOUR_TOKEN';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // UTF-8 디코딩을 명시적으로 처리
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      } else {
        print('AI Service Error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling AI service: $e');
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
      final dateString =
          '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

      // 트랜잭션으로 유저 문서 내 upload_counters 필드 증가
      final userRef = _firestore.collection('users').doc(uid);
      int sequenceNumber = 1;

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (snapshot.exists) {
          final data = snapshot.data();
          final currentCount = data?['upload_counters'] as int? ?? 0;
          sequenceNumber = currentCount + 1;
          transaction.update(userRef, {'upload_counters': sequenceNumber});
        } else {
          // 문서가 없는 경우(드문 경우) 생성 및 초기화
          sequenceNumber = 1;
          transaction.set(userRef, {
            'upload_counters': sequenceNumber,
          }, SetOptions(merge: true));
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

      // 3. 병렬 실행: Storage 업로드 & AI 분석 요청
      final results = await Future.wait([
        // Task 1: Upload to Storage and get URL
        ref.putFile(fileToUpload, metadata).then((task) => task.ref.getDownloadURL()),
        // Task 2: Upload to AI Service
        _uploadToAiService(fileToUpload),
      ]);

      final downloadUrl = results[0] as String;
      final aiResult = results[1] as Map<String, dynamic>?;

      // 4. Firestore 데이터 준비
      final Map<String, dynamic> firestoreData = {
        'createdAt': FieldValue.serverTimestamp(),
        'estimateCost': null,
        'imageUploadUrl': downloadUrl,
        'imageDamageUrl': null,
        'imageDamagePartUrl': null,
        'note': null,
      };

      // AI 결과가 있으면 병합
      if (aiResult != null) {
        firestoreData.addAll(aiResult);
        // AI 결과에 따라 imageDamageUrl 등을 매핑해야 한다면 여기서 처리
        // 예: firestoreData['imageDamageUrl'] = aiResult['analyzed_image_url'];
      }

      // 5. Firestore에 estimate_history 서브컬렉션에 문서 추가
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('estimate_history')
          .doc('$fileName.jpg')
          .set(firestoreData);

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }
}
