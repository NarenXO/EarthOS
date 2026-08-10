/*
|--------------------------------------------------------------------------
| EarthOS
| File: profile_screen.dart
| Feature: Profile Module
| Author: Naren
|--------------------------------------------------------------------------
| Personal User Profile, Metrics, Achievements, and Certificates
|--------------------------------------------------------------------------
*/

import 'package:flutter/material.dart';
import 'package:earthos/core/constants/app_colors.dart';
import 'package:earthos/core/config/app_config.dart';
import 'package:earthos/core/services/user_identity_service.dart';
import 'package:earthos/features/report/services/report_service.dart';
import 'package:earthos/features/profile/models/certificate_model.dart';
import 'package:earthos/features/profile/widgets/environmental_certificate_card.dart';
import 'package:earthos/features/achievements/achievement_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserIdentityService _userIdentityService = UserIdentityService();
  final ReportService _reportService = ReportService();
  
  Map<String, dynamic>? _userImpact;
  bool _isLoading = true;
  String _userName = AppConfig.author;

  @override
  void initState() {
    super.initState();
    _fetchUserImpact();
  }

  Future<void> _fetchUserImpact() async {
    try {
      final user = await _userIdentityService.getOrCreateUser();
      final impact = await _reportService.fetchUserImpact(user.id);
      setState(() {
        _userImpact = impact;
        _userName = user.name.isNotEmpty ? user.name : AppConfig.author;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Profile"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ===============================
            // USER HEADER
            // ===============================
            _buildUserHeader(context),

            const SizedBox(height: 30),

            // ===============================
            // PERSONAL IMPACT METRICS (4 CARDS)
            // ===============================
            Text(
              "Your Environmental Impact",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildRewardsGrid(),

            const SizedBox(height: 30),

            // ===============================
            // ACHIEVEMENTS SECTION
            // ===============================
            Text(
              "🏆 Rewards & Achievements",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildAchievementsSection(),

            const SizedBox(height: 30),

            // ===============================
            // CERTIFICATE SECTION
            // ===============================
            Text(
              "📜 Impact Certificates",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildCertificateCard(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // USER HEADER
  // =========================================================
  Widget _buildUserHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: Text(
                  _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userName,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Level 4 • Environmental Guardian",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: 0.65,
              minHeight: 10,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "650 / 1000 XP to next level",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PERSONAL METRICS GRID
  // =========================================================
  Widget _buildRewardsGrid() {
    final totalReports = _userImpact?['totalReports'] ?? 0;
    final verifiedReports = _userImpact?['verifiedReports'] ?? 0;
    final totalCarbonImpact = (userImpact['totalCarbonImpact'] as num?)?.toDouble() ?? 0.0;
    final totalVerifiedCarbon = (userImpact['totalVerifiedCarbon'] as num?)?.toDouble() ?? 0.0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _RewardCard(title: "Your Reports", value: totalReports.toString()),
        _RewardCard(
          title: "Verified Cleanups",
          value: verifiedReports.toString(),
        ),
        _RewardCard(
          title: "Total CO₂ Impact (kg)",
          value: totalCarbonImpact.toStringAsFixed(1),
        ),
        _RewardCard(
          title: "CO₂ Diverted (kg)",
          value: totalVerifiedCarbon.toStringAsFixed(1),
        ),
      ],
    );
  }

  get userImpact => _userImpact ?? {};

  // =========================================================
  // ACHIEVEMENTS SECTION
  // =========================================================
  Widget _buildAchievementsSection() {
    final achievements = AchievementService.calculateAchievements(_userImpact);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: achievements.map((ach) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Text(
                  ach.icon,
                  style: TextStyle(
                    fontSize: 28,
                    color: ach.isUnlocked ? null : Colors.grey,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ach.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ach.isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
                            ),
                          ),
                          if (ach.isUnlocked)
                            const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ach.description,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ach.progress,
                          minHeight: 6,
                          backgroundColor: AppColors.border,
                          color: ach.isUnlocked ? AppColors.primary : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // =========================================================
  // CERTIFICATE CARD
  // =========================================================
  Widget _buildCertificateCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Environmental Impact Certificate",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Generate your official environmental impact certificate based on verified cleanups.",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: _generateCertificate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text("Generate Certificate"),
          ),
        ],
      ),
    );
  }

  void _generateCertificate() async {
    if (_userImpact == null) return;

    final user = await _userIdentityService.getOrCreateUser();
    final certificate = Certificate(
      userName: user.name,
      verifiedCleanups: (_userImpact!['verifiedReports'] as num?)?.toInt() ?? 0,
      carbonDiverted: (_userImpact!['totalVerifiedCarbon'] as num?)?.toDouble() ?? 0.0,
      generatedAt: DateTime.now(),
    );

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: EnvironmentalCertificateCard(certificate: certificate),
          ),
        ),
      );
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    );
  }
}

// =============================================================
// REWARD CARD
// =============================================================
class _RewardCard extends StatelessWidget {
  final String title;
  final String value;

  const _RewardCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}