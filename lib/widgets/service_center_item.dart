import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/service_center.dart';
import '../models/review.dart';
import '../screens/write_review_screen.dart';

class ServiceCenterItem extends StatelessWidget {
  final ServiceCenter shop;
  final bool isExpanded;
  final VoidCallback onTap;

  const ServiceCenterItem({
    super.key,
    required this.shop,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? Colors.blueAccent
              : Theme.of(context).dividerColor,
          width: isExpanded ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isExpanded ? 0.08 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.mapPin,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shop.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            shop.address,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (shop.tel.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              shop.tel,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          // 평점과 리뷰 갯수를 전화번호 아래에 배치
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.star,
                                size: 12,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                shop.rating.toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '리뷰 ${shop.reviewCount}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              if (shop.distanceFromUser > 0) ...[
                                const SizedBox(width: 12),
                                const Icon(
                                  LucideIcons.navigation,
                                  size: 10,
                                  color: Colors.blueAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${shop.distanceFromUser.toStringAsFixed(1)}km',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ],
                ),
              ),
              if (isExpanded) _buildExpandedSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSection(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '최신 리뷰',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 12),
              if (shop.latestReviews.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '등록된 리뷰가 없습니다.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )
              else
                ...shop.latestReviews.map(
                  (review) => _buildReviewItem(context, review),
                ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WriteReviewScreen(shop: shop),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '리뷰 쓰러 가기',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _maskName(String name) {
    if (name.length <= 1) return name;
    if (name.length == 2) return '${name[0]}*';

    // 3글자 이상인 경우 가운데를 마스킹
    final String first = name.substring(0, 1);
    final String last = name.substring(name.length - 1);
    final String middle = '*' * (name.length - 2);

    return '$first$middle$last';
  }

  Widget _buildReviewItem(BuildContext context, Review review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _maskName(review.userName),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    size: 10,
                    color: index < review.rating.floor()
                        ? Colors.amber
                        : Colors.grey[300],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (review.imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                review.imageUrl!,
                width: double.infinity,
                height: 150,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            review.comment,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
