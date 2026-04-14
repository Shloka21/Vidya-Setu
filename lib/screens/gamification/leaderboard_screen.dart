import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import 'package:vidyasetu/services/localization_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestore = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _leaderboardData = [];
  Map<String, dynamic>? _currentUserRank;
  bool _loading = true;
  int _userIndexInList = -1;
  bool _usingMockData = false;

  final List<Map<String, dynamic>> _mockChampions = [
    {'name': 'Alex Rivera', 'points': 2850, 'level': 8, 'streak': 15, 'uid': 'mock1'},
    {'name': 'Sarah Chen', 'points': 2420, 'level': 7, 'streak': 22, 'uid': 'mock2'},
    {'name': 'James Wilson', 'points': 2100, 'level': 6, 'streak': 9, 'uid': 'mock3'},
    {'name': 'Priya Singh', 'points': 1850, 'level': 6, 'streak': 12, 'uid': 'mock4'},
    {'name': 'Emma Vance', 'points': 1500, 'level': 5, 'streak': 7, 'uid': 'mock5'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final currentUid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (currentUid == null) return;

    try {
      final userRank = await _firestore.getUserRankData(currentUid);
      if (mounted) {
        setState(() {
          _currentUserRank = userRank;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching user rank: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _scrollToMyRank() {
    if (_userIndexInList >= 0 && _userIndexInList < _leaderboardData.length) {
      // Account for the podium header (approx 280px) + items before user
      final itemsBeforeUser = (_userIndexInList - 3).clamp(0, _leaderboardData.length);
      final offset = 300.0 + (itemsBeforeUser * 82.0);
      _scrollController.animateTo(
        offset.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    } else if (_currentUserRank != null) {
      // User is beyond the list, scroll to bottom to show pinned card
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('leaderboard')),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentBlue,
          labelColor: AppTheme.accentBlue,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          tabs: [
            Tab(text: context.tr('weekly')),
            Tab(text: context.tr('monthly')),
            Tab(text: context.tr('all_time')),
          ],
        ),
      ),
      floatingActionButton: (_userIndexInList >= 3 || _currentUserRank != null)
          ? FloatingActionButton.extended(
              onPressed: _scrollToMyRank,
              backgroundColor: AppTheme.primaryNavy,
              icon: Icon(Icons.my_location_rounded, size: 20),
              label: Text(
                context.tr('my_rank'),
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboardData.isEmpty && !_usingMockData
              ? _buildEmpty()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaderboardContent(),
                    _buildLeaderboardContent(isTimeLimited: true),
                    _buildLeaderboardContent(),
                  ],
                ),
    );
  }

  Widget _buildLeaderboardContent({bool isTimeLimited = false}) {
    if (isTimeLimited && !_usingMockData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 48, color: AppTheme.accentPurple.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('Coming Soon!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Temporal leaderboards are currently in development.', 
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
          ],
        ),
      );
    }
    return _buildLeaderboard();
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          SizedBox(height: 16),
          Text(context.tr('no_leaderboard_data_yet'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 16)),
          SizedBox(height: 8),
          Text(context.tr('start_studying_to_earn_points'), style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    final currentUid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.leaderboardStream(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && _leaderboardData.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData) {
          final data = snapshot.data!.docs.asMap().entries.map((e) {
            final d = e.value.data() as Map<String, dynamic>;
            d['rank'] = e.key + 1;
            return d;
          }).toList();
          
          _leaderboardData = data;
          _userIndexInList = _leaderboardData.indexWhere((d) => d['uid'] == currentUid);
          _usingMockData = _leaderboardData.isEmpty;
        }

        final listItems = _leaderboardData.length > 3
            ? _leaderboardData.sublist(3)
            : <Map<String, dynamic>>[];

        return RefreshIndicator(
          onRefresh: () async {
            // Streams refresh automatically, but we can re-sync My Rank if needed
            if (currentUid != null && _userIndexInList == -1) {
              final userRank = await _firestore.getUserRankData(currentUid);
              if (mounted) setState(() => _currentUserRank = userRank);
            }
          },
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            itemCount: listItems.length + 2, // +1 for podium + 1 for pinned user card
            itemBuilder: (context, index) {
              if (index == 0) {
                // Top 3 podium
                if (_leaderboardData.length >= 3) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      height: 220,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _podiumItem(_leaderboardData[1], 2, 150, currentUid),
                          _podiumItem(_leaderboardData[0], 1, 200, currentUid),
                          _podiumItem(_leaderboardData[2], 3, 120, currentUid),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              if (index == listItems.length + 1) {
                // Pinned current user card (if not in top 50)
                if (_userIndexInList == -1 && _currentUserRank != null) {
                  return _buildPinnedUserCard(_currentUserRank!, currentUid);
                }
                return const SizedBox.shrink();
              }

              final listIdx = index - 1;
              return _rankItem(listItems[listIdx], currentUid);
            },
          ),
        );
      },
    );
  }

  Widget _podiumItem(Map<String, dynamic> user, int position, double height, String? currentUid) {
    final colors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};
    final name = (user['name'] as String?) ?? 'User';
    final points = user['points'] ?? 0;
    final isCurrentUser = user['uid'] == currentUid;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Crown for #1
          if (position == 1)
            const Text('👑', style: TextStyle(fontSize: 24)),
          Text(medals[position]!, style: const TextStyle(fontSize: 30)),
          const SizedBox(height: 6),
          // Avatar with glow for current user
          Container(
            width: position == 1 ? 60 : 50,
            height: position == 1 ? 60 : 50,
            decoration: BoxDecoration(
              color: colors[position]!.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrentUser ? AppTheme.accentBlue : colors[position]!,
                width: isCurrentUser ? 4 : 3,
              ),
              boxShadow: isCurrentUser
                  ? [
                      BoxShadow(
                        color: AppTheme.accentBlue.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : position == 1
                      ? [
                          BoxShadow(
                            color: colors[1]!.withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: isCurrentUser ? AppTheme.accentBlue : colors[position],
                  fontSize: position == 1 ? 26 : 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Name + "You" label
          Text(
            isCurrentUser ? context.tr('you') : name.split(' ')[0],
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isCurrentUser ? AppTheme.accentBlue : Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$points XP',
            style: const TextStyle(
              color: AppTheme.accentBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Podium bar
          Container(
            width: double.infinity,
            height: (height - 110).clamp(10, 100),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors[position]!.withOpacity(0.4),
                  colors[position]!.withOpacity(0.1),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(
                color: colors[position]!.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '#$position',
                style: TextStyle(
                  color: colors[position],
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankItem(Map<String, dynamic> user, String? currentUid) {
    final name = (user['name'] as String?) ?? 'User';
    final points = user['points'] ?? 0;
    final level = user['level'] ?? 1;
    final streak = user['streak'] ?? 0;
    final rank = user['rank'] ?? 0;
    final isCurrentUser = user['uid'] == currentUid;

    // Rank display: Emoji for Top 3, #Rank for others
    Widget rankWidget;
    if (rank == 1) rankWidget = const Text('🥇', style: TextStyle(fontSize: 22));
    else if (rank == 2) rankWidget = const Text('🥈', style: TextStyle(fontSize: 22));
    else if (rank == 3) rankWidget = const Text('🥉', style: TextStyle(fontSize: 22));
    else {
      rankWidget = Text(
        '#$rank',
        style: TextStyle(
          color: isCurrentUser
              ? AppTheme.accentBlue
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? AppTheme.accentBlue.withOpacity(0.12)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: isCurrentUser
              ? Border.all(color: AppTheme.accentBlue.withOpacity(0.5), width: 2.5)
              : Border.all(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: isCurrentUser
                  ? AppTheme.accentBlue.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: isCurrentUser ? 15 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Rank number/emoji
            SizedBox(
              width: 40,
              child: Center(child: rankWidget),
            ),
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? LinearGradient(
                        colors: [
                          AppTheme.accentBlue,
                          AppTheme.accentBlue.withOpacity(0.7),
                        ],
                      )
                    : null,
                color: isCurrentUser ? null : AppTheme.accentBlue.withOpacity(0.1),
                shape: BoxShape.circle,
                border: isCurrentUser ? Border.all(color: Colors.white, width: 2) : null,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : AppTheme.accentBlue,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Name + stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          isCurrentUser ? name : name,
                          style: TextStyle(
                            color: isCurrentUser
                                ? AppTheme.accentBlue
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.accentBlue,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: AppTheme.accentBlue.withOpacity(0.3), blurRadius: 4),
                            ],
                          ),
                          child: Text(
                            context.tr('you').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Level $level • 🔥 ${streak}d streak',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Points badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? const LinearGradient(
                        colors: [AppTheme.accentBlue, AppTheme.accentPurple],
                      )
                    : null,
                color: isCurrentUser ? null : AppTheme.accentPurple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                boxShadow: isCurrentUser ? [
                   BoxShadow(color: AppTheme.accentBlue.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2)),
                ] : [],
              ),
              child: Text(
                '$points XP',
                style: TextStyle(
                  color: isCurrentUser ? Colors.white : AppTheme.accentPurple,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Pinned card for user who is not in the top 50
  Widget _buildPinnedUserCard(Map<String, dynamic> user, String? currentUid) {
    final name = (user['name'] as String?) ?? 'You';
    final points = user['points'] ?? 0;
    final rank = user['rank'] ?? '?';
    final level = user['level'] ?? 1;
    final streak = user['streak'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryNavy, Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.accentBlue.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryNavy.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentBlue,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppTheme.accentBlue.withOpacity(0.4), blurRadius: 8),
                  ],
                ),
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('your_current_placement'),
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  '$points XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.1), height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(Icons.trending_up_rounded, 'Level $level', 'Progression'),
              _statItem(Icons.local_fire_department_rounded, '$streak Days', 'Streak'),
              _statItem(Icons.emoji_events_rounded, 'Rank #$rank', 'Global'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.accentBlue, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10)),
      ],
    );
  }
}
