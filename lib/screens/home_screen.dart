import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../providers/shop_provider.dart';
import '../providers/estimate_provider.dart';
import '../widgets/custom_search_bar.dart';
import '../utils/consumer_design.dart';
import '../widgets/sophisticated_loading_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _imageUrl;
  bool _isAnalyzing = false;
  bool _isUploading = false;
  bool _showPartImage = false; // [추가] 부품 이미지 전환 상태
  Map<String, dynamic>? _result;
  final StorageService _storageService = StorageService();
  StreamSubscription? _subscription;
  double _analysisProgress = 0.0;
  Timer? _progressTimer;

  // [추가] 업로드 시작 시간을 기록하여 과거 데이터 필터링
  DateTime? _uploadStartTime;

  @override
  void dispose() {
    _subscription?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startProgressSimulation() {
    setState(() {
      _analysisProgress = 0.0;
      _showPartImage = false; // 이미지 업로드 시 초기화
    });
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (mounted) {
        setState(() {
          if (_analysisProgress < 0.95) {
            _analysisProgress += 0.005;
          } else if (_analysisProgress < 0.99) {
            _analysisProgress += 0.001;
          }
        });
      }
    });
  }

  void _stopProgressSimulation() {
    _progressTimer?.cancel();
    _progressTimer = null;
    setState(() {
      _analysisProgress = 1.0;
    });
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
                _stopProgressSimulation();
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
                    'analyzedImageUrl': data['damageImageUrl'],
                    'partImageUrl': data['partImageUrl'], // [추가] 부품 분석 이미지 URL
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
        _startProgressSimulation();
        setState(() {
          _imageUrl = imageUrl;
          _isUploading = false;
          _isAnalyzing = true;
        });

        // Firestore 실시간 리스너 시작
        _listenForAnalysisResult();
      } catch (e) {
        if (!mounted) return;
        _stopProgressSimulation();
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

  Future<String?> _saveEstimate() async {
    if (_result == null) return null;

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

    if (title == null || title.isEmpty) return null;

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      final docRef = await FirebaseFirestore.instance
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
      if (!mounted) return docRef.id;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('견적이 저장되었습니다.')));
      return docRef.id;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      return null;
    }
  }

  Future<void> _handleRequestToShops() async {
    // 1. 견적이 이미 저장되었는지 확인 (이 화면에서는 _imageUrl이 있고 분석 완료 상태임)
    // 하지만 Firestore ID가 필요하므로 저장을 먼저 유도하거나 저장된 ID를 관리해야 함.
    // 간단히 하기 위해, 요청 시점에 저장을 먼저 진행함.

    String? estimateId;

    // 이미 저장된 경우를 체크할 변수가 현재는 없으므로 일단 저장을 호출하거나,
    // 저장 성공 후 얻은 ID를 사용해야 함.
    estimateId = await _saveEstimate();

    if (estimateId == null) return;

    if (!mounted) return;

    // 2. 요청 사항 입력 다이얼로그 띄우기
    final String? userRequest = await _showRequestDialog();
    if (userRequest == null) return;

    if (!mounted) return;

    // 3. 정비소 정보 가져오기 (ShopProvider 사용)
    final shopProvider = context.read<ShopProvider>();
    final estimateProvider = context.read<EstimateProvider>();

    if (shopProvider.shops.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('주변 10km 이내에 정비소가 없습니다.')));
      return;
    }

    try {
      // 로딩 표시
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주변 정비소에 견적 요청을 전송 중입니다...')),
      );

      // Estimate 객체 생성 (Provider의 sendEstimateToNearbyShops Expects Estimate)
      final estimate = Estimate(
        id: estimateId,
        title: _result!['damage'], // 임시
        date: DateTime.now().toIso8601String(),
        damage: _result!['damage'],
        price: _result!['estimatedPrice'],
        status: '저장됨',
        recommendations: List<String>.from(_result!['recommendations']),
        imageUrl: _imageUrl ?? _result?['analyzedImageUrl'],
      );

      await estimateProvider.sendEstimateToNearbyShops(
        estimate: estimate,
        shops: shopProvider.shops,
        userRequest: userRequest,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주변 정비소에 수리 요청을 성공적으로 보냈습니다.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('요청 전송 실패: $e')));
    }
  }

  Future<String?> _showRequestDialog() async {
    final TextEditingController requestController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('정비소 견적 요청'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('정비소에 전달할 요청 사항을 입력해주세요.'),
              const SizedBox(height: 16),
              TextField(
                controller: requestController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '예: 범퍼 도색 비용 포함인가요? 대차 가능한가요?',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, requestController.text.trim()),
              child: const Text('보내기'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 100),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: CustomSearchBar(
                onSearch: (value) {
                  // TODO: 홈 화면 통합 검색 기능 구현
                },
              ),
            ),
            // Upload Card / analyzing / result
            if (!_isAnalyzing && !_isUploading && _result == null) ...[
              // Hero Section
              Column(
                children: [
                  const SizedBox(height: 8),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: PixieMascot(status: 'idle', size: 96),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '안녕하세요! \nAI 정비사 픽시가 도와드릴게요',
                    textAlign: TextAlign.center,
                    style: ConsumerTypography.h1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '파손된 부위 사진을 올려주시면\n빠르게 견적을 내어드려요.',
                    textAlign: TextAlign.center,
                    style: ConsumerTypography.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
              _buildUploadCard(),
            ] else if (_isUploading || _isAnalyzing) ...[
              const SizedBox(height: 24),
              _buildAnalyzingState(),
            ] else if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResultView(),
            ],

            const SizedBox(height: 120), // Bottom padding for nav
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 380,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: ConsumerColor.slate100),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: ConsumerColor.brand50,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: ConsumerColor.brand100, width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.plus,
                      size: 48,
                      color: ConsumerColor.brand300,
                    ),
                  ),
                ),
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ConsumerColor.brand500,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      'TOUCH!',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text('사진 업로드하기', style: ConsumerTypography.h2),
            const SizedBox(height: 8),
            Text('여기를 눌러서 사진을 선택하세요', style: ConsumerTypography.bodyMedium),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildSmallActionBtn(LucideIcons.camera, '카메라'),
                const SizedBox(width: 12),
                _buildSmallActionBtn(LucideIcons.image, '갤러리'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallActionBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: ConsumerColor.brand50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ConsumerColor.brand100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: ConsumerColor.brand600),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: ConsumerColor.brand600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingState() {
    return SophisticatedLoadingScreen(
      progress: _analysisProgress,
      statusText: _isUploading ? '사진을 업로드 중...' : 'AI가 분석하고 있어요...',
      imageUrl: _imageUrl,
    );
  }

  Widget _buildResultView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: ConsumerColor.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.checkCircle2,
                color: Colors.green,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text('견적 분석 완료', style: ConsumerTypography.h2),
            ],
          ),
          const SizedBox(height: 24),
          if (_result!['analyzedImageUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // 기본 분석 이미지 (하단)
                  Image.network(
                    _result!['analyzedImageUrl'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  // 부품 분석 이미지 (상단, 투명도 적용)
                  if (_result!['partImageUrl'] != null)
                    Opacity(
                      opacity: 0.6, // 투명도 조절로 두 이미지를 합성한 것처럼 보여줌
                      child: Image.network(
                        _result!['partImageUrl'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text('분석 결과', style: ConsumerTypography.bodySmall),
          const SizedBox(height: 4),
          Text(
            _result!['damage'],
            style: ConsumerTypography.bodyLarge.copyWith(
              color: ConsumerColor.slate800,
            ),
          ),
          const SizedBox(height: 20),
          Text('예상 수리비', style: ConsumerTypography.bodySmall),
          const SizedBox(height: 4),
          Text(
            _result!['estimatedPrice'],
            style: ConsumerTypography.h1.copyWith(
              color: ConsumerColor.brand500,
              fontSize: 26,
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
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '견적 저장',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _handleRequestToShops,
              style: ElevatedButton.styleFrom(
                backgroundColor: ConsumerColor.brand500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '정비소에 견적 요청하기',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _result = null),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: ConsumerColor.brand200),
                foregroundColor: ConsumerColor.brand500,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                '다른 사진 업로드',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
