import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ServiceCenterService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<QueryDocumentSnapshot>> searchServiceCenters(
    String keyword,
  ) async {
    final String trimmed = keyword.trim();
    if (trimmed.isEmpty) return [];

    // 1. 키워드 분류 (행정구역 vs 이름/기타)
    final parts = trimmed.split(RegExp(r'\s+'));
    final Map<String, String> regionMap = {};
    final List<String> nameKeywords = [];

    for (var p in parts) {
      if (p.endsWith('도') || p.contains('특별자치도')) {
        regionMap['addr_sido'] = p;
      } else if (p.endsWith('시') || p.endsWith('군')) {
        // '서울특별시', '부산광역시' 등은 시도 단위로 처리
        if (p.contains('특별') || p.contains('광역')) {
          regionMap['addr_sido'] = p;
        } else {
          regionMap['addr_sigungu'] = p;
        }
      } else if (p.endsWith('구')) {
        regionMap['addr_gu'] = p;
      } else if (p.endsWith('읍') || p.endsWith('면')) {
        regionMap['addr_eupmyeon'] = p;
      } else if (p.endsWith('동')) {
        regionMap['addr_dong'] = p;
      } else {
        // 행정구역 키워드가 아니면 이름 검색용 키워드로 분류
        nameKeywords.add(p);
      }
    }

    final ref = _firestore.collection('service_centers');

    // 2. 지역 키워드가 없는 경우: 이름 및 주소 전체 검색 (OR 조건)
    if (regionMap.isEmpty) {
      try {
        final results = await Future.wait([
          // 이름 검색
          ref
              .where('name', isGreaterThanOrEqualTo: trimmed)
              .where('name', isLessThan: trimmed + '\uf8ff')
              .get(),
          // 주소 검색
          ref
              .where('address', isGreaterThanOrEqualTo: trimmed)
              .where('address', isLessThan: trimmed + '\uf8ff')
              .get(),
        ]);

        final nameDocs = results[0].docs;
        final addressDocs = results[1].docs;

        // 중복 제거 및 병합
        final Map<String, QueryDocumentSnapshot> uniqueDocs = {};
        for (var doc in nameDocs) {
          uniqueDocs[doc.id] = doc;
        }
        for (var doc in addressDocs) {
          uniqueDocs[doc.id] = doc;
        }

        return uniqueDocs.values.toList();
      } catch (e) {
        debugPrint('이름/주소 검색 중 오류 발생: $e');
        return [];
      }
    }

    // 3. 지역 키워드가 있는 경우: 지역 기반 필터링 + 이름 키워드 추가 확인
    // 검색 우선순위 (가장 구체적인 단위부터)
    const specificityOrder = [
      'addr_dong',
      'addr_eupmyeon',
      'addr_gu',
      'addr_sigungu',
      'addr_sido',
    ];

    String? primaryField;
    for (var f in specificityOrder) {
      if (regionMap.containsKey(f)) {
        primaryField = f;
        break;
      }
    }

    // primaryField는 regionMap이 비어있지 않으므로 null일 수 없지만 안전장치
    if (primaryField == null) return [];

    try {
      // 4. 가장 구체적인 지역으로 1차 검색 (인덱스 이슈 방지)
      final QuerySnapshot result = await ref
          .where(primaryField, isEqualTo: regionMap[primaryField])
          .get();

      // 5. 메모리 필터링: 나머지 지역 키워드 + 이름 키워드 매칭
      final filteredDocs = result.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        bool matches = true;

        // (1) 나머지 지역 키워드 확인
        regionMap.forEach((field, value) {
          if (field != primaryField) {
            // 데이터가 null이거나 입력한 값과 다르면 탈락
            if (data[field] == null ||
                !data[field].toString().contains(value)) {
              matches = false;
            }
          }
        });

        // (2) 이름 키워드 확인 (있는 경우)
        if (matches && nameKeywords.isNotEmpty) {
          final shopName = (data['name'] ?? '').toString();
          // 모든 이름 키워드가 상점 이름에 포함되어야 함 (AND 조건)
          for (var keyword in nameKeywords) {
            if (!shopName.contains(keyword)) {
              matches = false;
              break;
            }
          }
        }

        return matches;
      }).toList();

      return filteredDocs;
    } catch (e) {
      debugPrint('지역 기반 검색 중 오류 발생: $e');
      return [];
    }
  }
}
