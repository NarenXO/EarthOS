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
import 'package:earthos/features/community/services/community_feed_service.dart';
import 'package:earthos/features/community/kudos_service.dart';
import 'package:earthos/features/community/gallery_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ReportService _reportService = ReportService();
  final UserIdentityService _userIdentityService = UserIdentityService();
  final CommunityFeedService _feedService = CommunityFeedService();
  final KudosService _kudosService = KudosService();
  
  List<Map<String, dynamic>> _leaderboard = [];
  List<Report> _upcomingEvents = [];
  List<Map<String, dynamic>> _feedActivities = [];
  List<Map<String, dynamic>> _transformations = [];
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
      final feed = await _feedService.fetchRecentActivity(limit: 20);
      final transformations = await _reportService.fetchTransformations();
      print('Leaderboard screen loaded: ${leaderboard.length} entries, ${events.length} events, ${feed.length} feed items, ${transformations.length} transformations');
      setState(() {
        _leaderboard = leaderboard;
        _upcomingEvents = events;
        _feedActivities = feed;
        _transformations = transformations;
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===============================
          // LIVE COMMUNITY FEED
          // ===============================
          _buildLiveFeedSection(),
          
          const SizedBox(height: 24),
          
          // ===============================
          // LEADERBOARD
          // ===============================
          Text(
            'Leaderboard',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          _leaderboard.isEmpty
              ? const Center(
                  child: Text(
                    "No verified cleanups yet",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                      onKudos: () => _sendKudos(entry['userId'] as String, entry['userName'] as String),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildLiveFeedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people, color: Color(0xFF00C896)),
            const SizedBox(width: 8),
            Text(
              'Live Community Feed',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF00C896), width: 1),
          ),
          child: _feedActivities.isEmpty
              ? const Center(
                  child: Text(
                    'No recent activity',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _feedActivities.length,
                  itemBuilder: (context, index) {
                    final activity = _feedActivities[index];
                    return _FeedActivityTile(activity: activity);
                  },
                ),
        ),
        const SizedBox(height: 24),
        // ===============================
        // BEFORE/AFTER GALLERY
        // ===============================
        Row(
          children: [
            const Icon(Icons.photo_library, color: Color(0xFF00C896)),
            const SizedBox(width: 8),
            Text(
              'Before/After Gallery',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const GalleryScreen(),
                  ),
                );
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_transformations.isEmpty)
          const Text(
            'No transformations yet',
            style: TextStyle(color: AppColors.textSecondary),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _transformations.take(5).length,
              itemBuilder: (context, index) {
                final transformation = _transformations[index];
                return _GalleryPreviewTile(
                  transformation: transformation,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GalleryScreen(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _sendKudos(String toUserId, String toUserName) async {
    final currentUser = await _userIdentityService.getOrCreateUser();
    if (currentUser.id == toUserId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot send kudos to yourself')),
        );
      }
      return;
    }

    final controller = TextEditingController();
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Send Kudos to $toUserName'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Add a message (optional)',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C896),
            ),
            child: const Text('Send Kudos'),
          ),
        ],
      ),
    );

    if (message != null) {
      try {
        await _kudosService.sendKudos(
          fromUserId: currentUser.id,
          fromUserName: currentUser.name,
          toUserId: toUserId,
          toUserName: toUserName,
          message: message.isNotEmpty ? message : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kudos sent!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error sending kudos: $e')),
          );
        }
      }
    }
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
  final VoidCallback? onKudos;

  const _LeaderboardTile({
    required this.rank,
    required this.userName,
    required this.carbonDiverted,
    required this.verifiedCount,
    required this.isTop3,
    this.onKudos,
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
              if (onKudos != null) ...[
                const SizedBox(height: 8),
                IconButton(
                  onPressed: onKudos,
                  icon: const Icon(Icons.favorite, color: Colors.red),
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
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

class _FeedActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _FeedActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final icon = activity['icon'] as String? ?? '🌱';
    final user = activity['user'] as String? ?? 'Anonymous';
    final action = activity['action'] as String? ?? 'took action';
    final ago = activity['ago'] as String? ?? 'just now';
    final carbon = activity['carbon'] as num? ?? 0;
    final title = activity['title'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$user $action',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (title.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                ago,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (carbon > 0) ...[
                const SizedBox(height: 2),
                Text(
                  '${carbon.toStringAsFixed(1)} kg',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF00C896),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _GalleryPreviewTile extends StatelessWidget {
  final Map<String, dynamic> transformation;
  final VoidCallback onTap;

  const _GalleryPreviewTile({
    required this.transformation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoBefore = transformation['photo_before'] as String?;
    final userName = transformation['created_by_name'] as String? ?? 'Anonymous';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColors.card,
        ),
        child: Stack(
          children: [
            if (photoBefore != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photoBefore,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.card,
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 32),
                        ),
                      );
                    },
                  ),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Text(
                userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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

class _EventDetailDialog extends StatefulWidget {
  final Report event;
  final VoidCallback onJoin;

  const _EventDetailDialog({
    required this.event,
    required this.onJoin,
  });

  @override
  State<_EventDetailDialog> createState() => _EventDetailDialogState();
}

class _EventDetailDialogState extends State<_EventDetailDialog> {
  final ReportService _reportService = ReportService();
  final UserIdentityService _userIdentityService = UserIdentityService();
  List<Map<String, dynamic>> _volunteers = [];
  bool _isLoadingVolunteers = false;
  final List<String> _roles = [
    'Waste Collector',
    'Photo Documenter',
    'Sorter',
    'Team Leader',
    'First Aid',
    'Refreshments',
  ];

  @override
  void initState() {
    super.initState();
    _fetchVolunteers();
  }

  Future<void> _fetchVolunteers() async {
    setState(() => _isLoadingVolunteers = true);
    final volunteers = await _reportService.fetchVolunteers(widget.event.id);
    setState(() {
      _volunteers = volunteers;
      _isLoadingVolunteers = false;
    });
  }

  Future<void> _signUpForRole(String role) async {
    final currentUser = await _userIdentityService.getOrCreateUser();
    
    // Check if already signed up for this event
    final alreadySignedUp = _volunteers.any(
      (v) => v['user_id'] == currentUser.id,
    );
    
    if (alreadySignedUp) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are already signed up for this event')),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign up as $role'),
        content: Text('Are you sure you want to sign up as $role?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C896),
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _reportService.signUpAsVolunteer(
          eventId: widget.event.id,
          userId: currentUser.id,
          userName: currentUser.name,
          role: role,
        );
        await _fetchVolunteers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Successfully signed up!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing up: $e')),
          );
        }
      }
    }
  }

  int _getRoleCount(String role) {
    return _volunteers.where((v) => v['role'] == role).length;
  }

  List<String> _getRoleUsers(String role) {
    return _volunteers
        .where((v) => v['role'] == role)
        .map((v) => v['user_name'] as String? ?? 'Unknown')
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event.title ?? widget.event.type),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.event.description != null) ...[
              Text(widget.event.description!),
              const SizedBox(height: 16),
            ],
            if (widget.event.eventDate != null) ...[
              _DetailRow(label: 'Date', value: widget.event.eventDate!),
              const SizedBox(height: 8),
            ],
            if (widget.event.venue != null) ...[
              _DetailRow(label: 'Venue', value: widget.event.venue!),
              const SizedBox(height: 8),
            ],
            _DetailRow(label: 'Organizer', value: widget.event.createdByName),
            const SizedBox(height: 8),
            _DetailRow(
              label: 'Participants',
              value: '${widget.event.participantsCount ?? 0}',
            ),
            if (widget.event.maxParticipants != null) ...[
              const SizedBox(height: 4),
              Text(
                'Max: ${widget.event.maxParticipants}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 24),
            const Text(
              'Volunteer Roles',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            if (_isLoadingVolunteers)
              const CircularProgressIndicator()
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _roles.map((role) {
                  final count = _getRoleCount(role);
                  final users = _getRoleUsers(role);
                  return InkWell(
                    onTap: () => _signUpForRole(role),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF00C896)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            role,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$count signed up',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (users.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              users.join(', '),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: widget.onJoin,
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
