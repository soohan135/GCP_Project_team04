import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _imageUrl;
  bool _isAnalyzing = false;
  bool _isUploading = false;
  Map<String, dynamic>? _result;
  final StorageService _storageService = StorageService();
  StreamSubscription? _subscription;

  // [추가] 업로드 시작 시간을 기록하여 과거 데이터 필터링
  DateTime? _uploadStartTime;

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _listenForAnalysisResult() {
    // 기존 구독 취소
    _subscription?.cancel();

    // damage_analyses 컬렉션에서 전체 사용자 중 가장 최신 문서를 감시
    // (테스트 시 userId가 "anonymous"인 경우를 대비해 필터를 풀고 가장 최근 것 1개를 가져옵니다)
    _subscription = FirebaseFirestore.instance
        .collection('damage_analyses')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            final data = doc.data();

            // 문서 생성 시간 확인 (업로드 시작 이후 데이터인지 확인하여 이전 결과가 뜨지 않게 함)
            DateTime docTime;
            try {
              if (data['timestamp'] is Timestamp) {
                docTime = (data['timestamp'] as Timestamp).toDate();
              } else if (data['timestamp'] is String) {
                docTime = DateTime.parse(data['timestamp']);
              } else {
                return;
              }
            } catch (e) {
              return;
            }

            if (_uploadStartTime != null &&
                docTime.isBefore(_uploadStartTime!)) {
              debugPrint("과거 데이터 무시함");
              return;
            }

            // 서버에서 저장한 필드명이 존재하는지 확인
            if (data.containsKey('damageImageUrl') &&
                data.containsKey('totalCost')) {
              _subscription?.cancel();
              _subscription = null;

              if (mounted) {
                setState(() {
                  _isAnalyzing = false;

                  // 가격 포맷팅 (숫자인 경우 하한 10%, 상한 20% 범위 적용)
                  final rawCost = data['totalCost'];
                  num? costNum;
                  if (rawCost is num) {
                    costNum = rawCost;
                  } else if (rawCost is String) {
                    costNum = num.tryParse(
                      rawCost.replaceAll(RegExp(r'[^0-9]'), ''),
                    );
                  }

                  String formattedPrice = '';
                  if (costNum != null) {
                    final minCost = (costNum * 0.9).toInt();
                    final maxCost = (costNum * 1.2).toInt();

                    String format(num n) =>
                        '₩' +
                        n.toInt().toString().replaceAllMapped(
                          RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"),
                          (Match m) => "${m[1]},",
                        );

                    formattedPrice = '${format(minCost)} ~ ${format(maxCost)}';
                  } else {
                    formattedPrice = rawCost.toString();
                  }

                  // 손상 부위 및 유형 추출 (details 필드 활용 및 한글 변환)
                  String damageDescription = '차량 손상 분석';
                  if (data['details'] != null &&
                      data['details'] is List &&
                      (data['details'] as List).isNotEmpty) {
                    final firstDetail = (data['details'] as List).first;
                    final rawPart = firstDetail['part'] ?? '';
                    final rawDamage = firstDetail['damage'] ?? '';

                    // 부품 명칭 한글 매핑
                    final partMap = {
                      'Front bumper': '앞 범퍼',
                      'Rear bumper': '뒷 범퍼',
                      'Bonnet': '보닛 (본네트)',
                      'Trunk lid': '트렁크 리드 (트렁크 문)',
                      'Front fender(R)': '앞 펜더 (오른쪽)',
                      'Front fender(L)': '앞 펜더 (왼쪽)',
                      'Rear fender(R)': '뒤 펜더 (오른쪽)',
                      'Rear fender(L)': '뒤 펜더 (왼쪽)',
                      'Front door(R)': '앞 문 (오른쪽)',
                      'Front door(L)': '앞 문 (왼쪽)',
                      'Rear door(R)': '뒷 문 (오른쪽)',
                      'Rear door(L)': '뒷 문 (왼쪽)',
                      'Side mirror(R)': '사이드 미러 (오른쪽)',
                      'Side mirror(L)': '사이드 미러 (왼쪽)',
                      'Head lights(R)': '헤드라이트 (오른쪽)',
                      'Head lights(L)': '헤드라이트 (왼쪽)',
                      'Front Wheel(R)': '앞 바퀴/휠 (오른쪽)',
                      'Front Wheel(L)': '앞 바퀴/휠 (왼쪽)',
                      'Rear Wheel(R)': '뒤 바퀴/휠 (오른쪽)',
                      'Rear Wheel(L)': '뒤 바퀴/휠 (왼쪽)',
                      'Rocker panel(R)': '로커 패널/사이드 실 (오른쪽)',
                      'Rocker panel(L)': '로커 패널/사이드 실 (왼쪽)',
                      'Windshield': '앞 유리 (윈드실드)',
                      'Rear windshield': '뒷 유리',
                    };

                    // 손상 종류 한글 매핑
                    final damageMap = {
                      'Scratched': '스크래치',
                      'Crushed': '찌그러짐',
                      'Broken': '파손',
                      'Separated': '이격',
                    };

                    final part = partMap[rawPart] ?? rawPart;
                    final damageType = damageMap[rawDamage] ?? rawDamage;

                    if (part.isNotEmpty && damageType.isNotEmpty) {
                      damageDescription = '$part - $damageType';
                    } else if (part.isNotEmpty) {
                      damageDescription = part;
                    }
                  }

                  // 화면에 띄울 결과 데이터 구성
                  _result = {
                    'damage': damageDescription,
                    'estimatedPrice': formattedPrice,
                    'analyzedImageUrl': data['damageImageUrl'], // AI 서버가 저장한 필드
                    'recommendations': [
                      '손상 부위 정밀 점검 필요',
                      '주변 부위 도장 상태 확인',
                      '견적서 세부 내역 확인 요망',
                    ],
                  };
                });
              }
            }
          }
        });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _isUploading = true;
        _result = null;
        _imageUrl = null;
        // [추가] 업로드 시작 시점 기록 (약간의 오차 보정을 위해 5초 정도 뺌)
        _uploadStartTime = DateTime.now().subtract(const Duration(seconds: 5));
      });

      // 사진 업로드
      try {
        final imageUrl = await _storageService.uploadCrashedCarPicture(image);
        if (!mounted) return;
        setState(() {
          _imageUrl = imageUrl;
          _isUploading = false;
          _isAnalyzing = true;
        });

        // Firestore 실시간 리스너 시작
        _listenForAnalysisResult();
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isUploading = false;
          _isAnalyzing = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('사진 업로드 실패: $e')));
      }
    }
  }

  Future<void> _saveEstimate() async {
    if (_result == null) return;

    final TextEditingController titleController = TextEditingController();

    // 다이얼로그로 제목 입력 받기
    final String? title = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('견적 저장'),
          content: TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: '견적 제목을 입력하세요 (예: 앞 범퍼 수리)',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, titleController.text.trim()),
              child: const Text('저장'),
            ),
          ],
        );
      },
    );

    if (title == null || title.isEmpty) return;

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('estimates')
          .add({
            'title': title,
            'damage': _result!['damage'],
            'estimatedPrice': _result!['estimatedPrice'],
            'recommendations': _result!['recommendations'],
            'date': DateTime.now().toIso8601String(),
            'imageUrl': _imageUrl,
            'analyzedImageUrl': _result?['analyzedImageUrl'],
          });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('견적이 저장되었습니다.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Text(
            'AI 기반 자동 견적 서비스',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.indigo[900],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            '차량 손상 사진을 업로드하면 즉시 수리 견적을 확인할 수 있습니다',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 48),

          if (!_isAnalyzing && !_isUploading && _result == null)
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 60),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        size: 40,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '손상된 차량 사진을 업로드하세요',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '클릭하여 이미지 추가',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    const Icon(
                      LucideIcons.upload,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
            ),

          if (_isUploading)
            Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  '사진을 업로드 중...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Firebase Storage에 사진을 저장하고 있습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),

          if (_isAnalyzing)
            Column(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                const Text(
                  'AI 서버에서 분석 중...',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '이미지를 바탕으로 수리 견적을 산출하고 있습니다.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),

          if (_result != null)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.checkCircle2,
                          color: Colors.green,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          '견적 분석 완료',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_result!['analyzedImageUrl'] != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _result!['analyzedImageUrl'],
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const Text(
                      '분석 결과',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _result!['damage'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '예상 수리비',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _result!['estimatedPrice'],
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      '권장 작업',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ...(_result!['recommendations'] as List).map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.circle,
                              size: 6,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(width: 12),
                            Text(task),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveEstimate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '견적 저장',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _result = null),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          '다른 사진 업로드하기',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
