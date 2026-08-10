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
import 'package:earthos/core/services/user_identity_service.dart';
import 'package:earthos/features/report/services/report_service.dart';
import 'package:earthos/features/report/models/report_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ReportService _reportService = ReportService();
  final UserIdentityService _userIdentityService = UserIdentityService();
  
  List<Map<String, dynamic>> _leaderboard = [];
  List<Report> _upcomingEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final leaderboard = await _reportService.fetchLeaderboard();
      final events = await _reportService.fetchUpcomingEvents();
      print('Leaderboard screen loaded: ${leaderboard.length} entries, ${events.length} events');
      setState(() {
        _leaderboard = leaderboard;
        _upcomingEvents = events;
        _isLoading = false;
      });
    } catch (e) {
      print('Leaderboard screen error: $e');
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
        title: const Text("Community & Events"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Leaderboard'),
                      Tab(text: 'Events'),
                      Tab(text: 'Meetups'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildLeaderboardTab(),
                        _buildEventsTab(),
                        _buildMeetupsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLeaderboardTab() {
    return _leaderboard.isEmpty
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
          );
  }

  Widget _buildEventsTab() {
    final cleanupEvents = _upcomingEvents.where((e) => e.type == 'cleanup_event').toList();
    return cleanupEvents.isEmpty
        ? const Center(
            child: Text(
              "No upcoming cleanup events",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cleanupEvents.length,
            itemBuilder: (context, index) {
              return _EventCard(
                event: cleanupEvents[index],
                onTap: () => _showEventDetails(cleanupEvents[index]),
              );
            },
          );
  }

  Widget _buildMeetupsTab() {
    final meetups = _upcomingEvents.where((e) => e.type == 'meetup').toList();
    return meetups.isEmpty
        ? const Center(
            child: Text(
              "No upcoming meetups",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meetups.length,
            itemBuilder: (context, index) {
              return _EventCard(
                event: meetups[index],
                onTap: () => _showEventDetails(meetups[index]),
              );
            },
          );
  }

  void _showEventDetails(Report event) {
    showDialog(
      context: context,
      builder: (context) => _EventDetailDialog(
        event: event,
        onJoin: () => _joinEvent(event),
      ),
    );
  }

  Future<void> _joinEvent(Report event) async {
    try {
      final user = await _userIdentityService.getOrCreateUser();
      await _reportService.joinEventWithName(event.id, user.name);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully joined event!')),
      );
      _fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join event: $e')),
      );
    }
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

class _EventCard extends StatelessWidget {
  final Report event;
  final VoidCallback onTap;

  const _EventCard({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.title ?? event.type,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (event.eventDate != null)
              Text(
                event.eventDate!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            if (event.venue != null) ...[
              const SizedBox(height: 4),
              Text(
                event.venue!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${event.participantsCount ?? 0} participants',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Join'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EventDetailDialog extends StatelessWidget {
  final Report event;
  final VoidCallback onJoin;

  const _EventDetailDialog({
    required this.event,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(event.title ?? event.type),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (event.description != null) ...[
              Text(event.description!),
              const SizedBox(height: 16),
            ],
            if (event.eventDate != null) ...[
              _DetailRow(label: 'Date', value: event.eventDate!),
              const SizedBox(height: 8),
            ],
            if (event.venue != null) ...[
              _DetailRow(label: 'Venue', value: event.venue!),
              const SizedBox(height: 8),
            ],
            _DetailRow(label: 'Organizer', value: event.createdByName),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Participants',
              value: '${event.participantsCount ?? 0}',
            ),
            if (event.maxParticipants != null) ...[
              const SizedBox(height: 4),
              Text(
                'Max: ${event.maxParticipants}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: onJoin,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
          ),
          child: const Text('Join Event'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
