/*
|--------------------------------------------------------------------------
| EarthOS
| File: leaderboard_screen.dart
| Feature: Community Module
| Author: Naren
|--------------------------------------------------------------------------
| Global Leaderboard - Ranked by Verified Carbon Diverted
|--------------------------------------------------------------------------
*/

import 'package:flutter/material.dart';
import 'package:earthos/core/constants/app_colors.dart';
import 'package:earthos/features/report/services/report_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ReportService _reportService = ReportService();
  
  List<Map<String, dynamic>> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    try {
      final leaderboard = await _reportService.fetchLeaderboard();
      setState(() {
        _leaderboard = leaderboard;
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
        title: const Text("Leaderboard"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboard.isEmpty
              ? const Center(
                  child: Text(
                    "No verified cleanups yet",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _leaderboard.length,
                  itemBuilder: (context, index) {
                    final entry = _leaderboard[index];
                    final rank = index + 1;
                    final isTop3 = rank <= 3;
                    return _LeaderboardTile(
                      rank: rank,
                      userName: entry['userName'] as String,
                      carbonDiverted: entry['carbonDiverted'] as double,
                      verifiedCount: entry['verifiedCount'] as int,
                      isTop3: isTop3,
                    );
                  },
                ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int rank;
  final String userName;
  final double carbonDiverted;
  final int verifiedCount;
  final bool isTop3;

  const _LeaderboardTile({
    required this.rank,
    required this.userName,
    required this.carbonDiverted,
    required this.verifiedCount,
    required this.isTop3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTop3 
            ? AppColors.primary.withOpacity(0.1)
            : AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTop3 ? AppColors.primary : AppColors.border,
          width: isTop3 ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          _buildRankBadge(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isTop3 ? AppColors.primary : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$verifiedCount verified cleanups',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${carbonDiverted.toStringAsFixed(1)} kg',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isTop3 ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              const Text(
                'CO₂e',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge() {
    Color badgeColor;
    if (rank == 1) {
      badgeColor = Colors.amber;
    } else if (rank == 2) {
      badgeColor = Colors.grey;
    } else if (rank == 3) {
      badgeColor = Colors.brown;
    } else {
      badgeColor = AppColors.textSecondary;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          rank.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
