import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import '../utils/mechanic_design.dart';
import '../widgets/custom_search_bar.dart';
import '../utils/consumer_design.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<AppUser?>(
      stream: authService.appUserStream,
      builder: (context, snapshot) {
        final appUser = snapshot.data;
        final isConsumer = appUser?.role == UserRole.consumer;

        final settingItems = [
          if (appUser != null &&
              appUser.role == UserRole.mechanic &&
              appUser.serviceCenterId != null)
            'shop_info',
          'dark_mode',
          'logout',
        ];

        final filteredItems = settingItems.where((item) {
          final query = _searchQuery.toLowerCase();
          if (item == 'dark_mode') return '다크 모드'.contains(query);
          if (item == 'logout') return '로그아웃'.contains(query);
          if (item == 'shop_info') return '내 정비소 정보'.contains(query);
          return true;
        }).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.only(
            top: isConsumer ? 110 : 24,
            left: 24,
            right: 24,
            bottom: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isConsumer)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CustomSearchBar(
                    onSearch: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              Text(
                '설정',
                style: isConsumer
                    ? ConsumerTypography.h1
                    : const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
              ),
              const SizedBox(height: 16),

              if (filteredItems.contains('shop_info') &&
                  appUser?.serviceCenterId != null) ...[
                _buildShopInfoSection(context, appUser!.serviceCenterId!),
                const SizedBox(height: 16),
              ],

              if (filteredItems.contains('dark_mode')) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isConsumer
                          ? ConsumerColor.brand100
                          : MechanicColor.primary100,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '다크 모드',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '시스템 테마를 블랙/화이트로 설정합니다',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme(value);
                        },
                        activeColor: isConsumer
                            ? Colors.blueAccent
                            : MechanicColor.primary500,
                        activeTrackColor: isConsumer
                            ? null
                            : MechanicColor.primary200,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (filteredItems.contains('logout')) ...[
                GestureDetector(
                  onTap: () async {
                    await authService.signOut();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            LucideIcons.logOut,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          '로그아웃',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              if (filteredItems.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text(
                      '일치하는 설정 항목이 없습니다.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShopInfoSection(BuildContext context, String shopId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('service_centers')
          .doc(shopId)
          .get(),
      builder: (context, snapshot) {
        String shopName = '불러오는 중...';
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          shopName = data['name'] ?? '이름 없음';
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MechanicColor.primary500.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: MechanicColor.primary500.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MechanicColor.primary500.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.home,
                      color: MechanicColor.primary500,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '내 정비소 정보',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: MechanicColor.primary600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildInfoRow('정비소 이름', shopName),
              const Divider(height: 24),
              _buildInfoRow('문서 ID', shopId, isCopyable: true),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isCopyable = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        InkWell(
          onTap: isCopyable
              ? () {
                  Clipboard.setData(ClipboardData(text: value));
                }
              : null,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (isCopyable) ...[
                const SizedBox(width: 8),
                const Icon(LucideIcons.copy, size: 14, color: Colors.grey),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
