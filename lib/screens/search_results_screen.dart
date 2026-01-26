import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/service_center_service.dart';
import '../models/service_center.dart';
import '../widgets/service_center_item.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({super.key, required this.query});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  String? _expandedShopId;

  @override
  Widget build(BuildContext context) {
    final searchService = Provider.of<ServiceCenterService>(
      context,
      listen: false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('"${widget.query}" 검색 결과'),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: searchService.searchServiceCenters(widget.query),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }

          final rawResults = snapshot.data ?? [];

          if (rawResults.isEmpty) {
            return const Center(child: Text('검색 결과가 없습니다.'));
          }

          // Convert snapshots to ServiceCenter models
          final results = rawResults.map((doc) {
            return ServiceCenter.fromGeoDocument(
              doc as DocumentSnapshot<Map<String, dynamic>>,
              0.0, // Search results might not have distance context here
            );
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Text(
                  '총 ${results.length}개의 정비소 발견',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final shop = results[index];
                    return ServiceCenterItem(
                      shop: shop,
                      isExpanded: _expandedShopId == shop.id,
                      onTap: () {
                        setState(() {
                          _expandedShopId = _expandedShopId == shop.id
                              ? null
                              : shop.id;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
