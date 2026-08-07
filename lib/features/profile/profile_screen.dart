/*
|--------------------------------------------------------------------------
| EarthOS
| File: profile_screen.dart
| Feature: Profile Module
| Author: Naren
|--------------------------------------------------------------------------
| Profile, Rewards, Certificates, and Leaderboards
|--------------------------------------------------------------------------
*/

import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/config/app_config.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            // REWARDS SECTION
            // ===============================
            Text(
              "Rewards & Achievements",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildRewardsGrid(),

            const SizedBox(height: 30),

            // ===============================
            // CERTIFICATE SECTION
            // ===============================
            Text(
              "Impact Certificates",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildCertificateCard(),

            const SizedBox(height: 30),

            // ===============================
            // LEADERBOARD SECTION
            // ===============================
            Text(
              "Leaderboard",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            _buildLeaderboardPreview(),

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
          Text(
            AppConfig.author,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            "Level 4 • Environmental Guardian",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
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
  // REWARDS GRID
  // =========================================================
  Widget _buildRewardsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: const [
        _RewardCard(title: "Verified Cleanups", value: "12"),
        _RewardCard(title: "CO₂e Prevented", value: "540kg"),
        _RewardCard(title: "Bounties Claimed", value: "6"),
        _RewardCard(title: "Certificates", value: "3"),
      ],
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
            "Cleanup Verification Certificate",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "CO₂e Prevented: 120kg\nVerified: 02 Aug 2026",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          ElevatedButton(
            onPressed: () {
              // Later: generate and download PDF
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text("Download Certificate"),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // LEADERBOARD PREVIEW
  // =========================================================
  Widget _buildLeaderboardPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Top Contributors",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "1. Alex — 980kg CO₂e\n2. Naren — 540kg CO₂e\n3. Priya — 420kg CO₂e",
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
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