import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/theme_provider.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';
import '../utils/mechanic_design.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context, listen: false);

    return StreamBuilder<AppUser?>(
      stream: authService.appUserStream,
      builder: (context, snapshot) {
        final appUser = snapshot.data;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '설정',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),

              if (appUser != null &&
                  appUser.role == UserRole.mechanic &&
                  appUser.serviceCenterId != null) ...[
                _buildShopInfoSection(context, appUser.serviceCenterId!),
                const SizedBox(height: 16),
              ],

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MechanicColor.primary100),
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
                      activeColor: MechanicColor.primary500,
                      activeTrackColor: MechanicColor.primary200,
                      inactiveThumbColor: MechanicColor.primary500,
                      inactiveTrackColor: MechanicColor.primary100,
                      trackOutlineColor: MaterialStateProperty.all(
                        MechanicColor.primary500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Logout Section
              GestureDetector(
                onTap: () async {
                  await authService.signOut();
                  // AuthWrapper will automatically handle redirection
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: MechanicColor.primary100),
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
                  // Simple visual feedback without state
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
