import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/service_center.dart';
import '../services/storage_service.dart';
import '../models/review.dart'; // Assuming Review model exists

class WriteReviewScreen extends StatefulWidget {
  final ServiceCenter shop;

  const WriteReviewScreen({super.key, required this.shop});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  int _rating = 5;
  final TextEditingController _commentController = TextEditingController();
  XFile? _image;
  bool _isUploading = false;
  final StorageService _storageService = StorageService();

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() {
        _image = image;
      });
    }
  }

  Future<void> _submitReview() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('리뷰 내용을 입력해주세요.')));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      String? imageUrl;
      if (_image != null) {
        imageUrl = await _storageService.uploadCrashedCarPicture(_image!);
      }

      final review = Review(
        id: '', // Firestore will generate
        userName: user.displayName ?? '익명',
        rating: _rating.toDouble(),
        comment: _commentController.text.trim(),
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
      );

      final shopRef = FirebaseFirestore.instance
          .collection('service_centers')
          .doc(widget.shop.id);

      final reviewsRef = shopRef.collection('reviews');

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. 정비소 정보 업데이트를 위해 먼저 기존 데이터 읽기 (트랜잭션 규칙: 읽기 우선)
        final shopSnap = await transaction.get(shopRef);

        // 2. 리뷰 추가 (쓰기)
        // 사용자가 여러 번 방문하여 리뷰를 남길 수 있도록 자동 생성 ID를 사용합니다.
        // 유저 식별을 위해 데이터 필드에 userId(UID)를 포함합니다.
        final newReviewRef = reviewsRef.doc();
        transaction.set(newReviewRef, {
          ...review.toMap(),
          'userId': user.uid, // 유저 식별을 위한 필드 추가
        });

        // 3. 정비소 정보 업데이트 (평점 및 리뷰 수)
        if (shopSnap.exists) {
          final data = shopSnap.data()!;
          final currentRating = (data['rating'] ?? 0.0).toDouble();
          final currentCount = (data['reviewCount'] ?? 0) as int;

          final newCount = currentCount + 1;
          final newRating =
              ((currentRating * currentCount) + _rating) / newCount;

          transaction.update(shopRef, {
            'rating': newRating,
            'reviewCount': newCount,
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('리뷰가 등록되었습니다.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('리뷰 등록 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.shop.name} 리뷰 작성'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '정비 서비스는 어떠셨나요?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 별점 선택기
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  icon: Icon(
                    LucideIcons.star,
                    color: index < _rating ? Colors.amber : Colors.grey[300],
                    size: 40,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            const Text(
              '리뷰 내용',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: '작업 내용, 친절도, 가격 등에 대한 후기를 남겨주세요.',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              '사진 추가',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(_image!.path),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(LucideIcons.camera, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isUploading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        '리뷰 등록하기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
