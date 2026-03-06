import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/app_card.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestore = FirestoreService();
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadLeaderboard();
    });
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loading = true);
    try {
      final snapshot = await _firestore.getLeaderboard(limit: 20);
      final data = snapshot.docs.asMap().entries.map((e) {
        final d = e.value.data() as Map<String, dynamic>;
        d['rank'] = e.key + 1;
        return d;
      }).toList();
      if (mounted) setState(() { _leaderboardData = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentBlue,
          labelColor: AppTheme.accentBlue,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'All Time'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _leaderboardData.isEmpty
              ? _buildEmpty()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeaderboard(),
                    _buildLeaderboard(),
                    _buildLeaderboard(),
                  ],
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('No leaderboard data yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 16)),
          const SizedBox(height: 8),
          Text('Start studying to earn points!', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    final currentUid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;

    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top 3 podium
            if (_leaderboardData.length >= 3)
              SizedBox(
                height: 200,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _podiumItem(_leaderboardData[1], 2, 140, currentUid),
                    _podiumItem(_leaderboardData[0], 1, 180, currentUid),
                    _podiumItem(_leaderboardData[2], 3, 110, currentUid),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Rest of the list
            ...List.generate(
              (_leaderboardData.length - 3).clamp(0, 17),
              (i) => _rankItem(_leaderboardData[i + 3], currentUid),
            ),
          ],
        ),
      ),
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
          Text(medals[position]!, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colors[position]!.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrentUser ? AppTheme.accentBlue : colors[position]!,
                width: isCurrentUser ? 4 : 3,
              ),
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(color: colors[position], fontSize: 22, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name.split(' ')[0],
            style: TextStyle(
              color: isCurrentUser ? AppTheme.accentBlue : Theme.of(context).colorScheme.onSurface,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
          Text('$points XP', style: TextStyle(color: AppTheme.accentBlue, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: (height - 100).clamp(10, 100),
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [colors[position]!.withOpacity(0.3), colors[position]!.withOpacity(0.1)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Text('#$position', style: TextStyle(color: colors[position], fontSize: 20, fontWeight: FontWeight.w700)),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Container(
          decoration: isCurrentUser
              ? BoxDecoration(
                  border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3), width: 2),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text('#$rank', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCurrentUser ? AppTheme.accentBlue.withOpacity(0.2) : AppTheme.accentBlue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(color: AppTheme.accentBlue, fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCurrentUser ? '$name (You)' : name,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Level $level • 🔥 ${streak}d streak',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentPurple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$points XP', style: TextStyle(color: AppTheme.accentPurple, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

