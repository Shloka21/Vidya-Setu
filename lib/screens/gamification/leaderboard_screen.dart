import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import '../../app/theme.dart';
import '../../app/routes.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final FirestoreService _firestore = FirestoreService();
  List<Map<String, dynamic>> _leaderboardData = [];
  Map<String, dynamic>? _currentUserRank;
  int _userIndexInList = -1;
  bool _usingMockData = false;
  final ScrollController _scrollController = ScrollController();
  
  static const LinearGradient royalGoldGradient = LinearGradient(
    colors: [
      Color(0xFFFFD700), // Gold
      Color(0xFFFDB931), // Golden Yellow
      Color(0xFFB8860B), // Dark Goldenrod
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    // Pre-fetch my specific rank data if I'm not in top 50
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadMyRank());
  }

  Future<void> _loadMyRank() async {
    final currentUid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid;
    if (currentUid != null) {
      final userRank = await _firestore.getUserRankData(currentUid);
      if (mounted) setState(() => _currentUserRank = userRank);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.watch<AuthProvider>().userModel?.uid;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.leaderboardStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _buildErrorState();
          
          if (snapshot.connectionState == ConnectionState.waiting && _leaderboardData.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            _processData(snapshot.data!.docs, currentUid);
          }

          if (_leaderboardData.isEmpty && !_usingMockData) {
            return _buildEmptyState();
          }

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildAppBar(),
                  _buildPodiumSection(currentUid),
                  _buildRankList(currentUid),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)), // Space for pinned card
                ],
              ),
              if (_userIndexInList == -1 && _currentUserRank != null)
                _buildPinnedUserCard(_currentUserRank!, currentUid),
            ],
          );
        },
      ),
    );
  }

  void _processData(List<DocumentSnapshot> docs, String? currentUid) {
    final data = docs.map((doc) {
      final map = doc.data() as Map<String, dynamic>;
      map['uid'] = doc.id;
      return map;
    }).where((m) {
      final role = (m['role'] as String?)?.toLowerCase() ?? '';
      return role == 'student';
    }).toList();

    // Local Sort
    data.sort((a, b) {
      final pa = (a['points'] ?? 0) as int;
      final pb = (b['points'] ?? 0) as int;
      return pb.compareTo(pa);
    });

    // Assign Ranks
    for (int i = 0; i < data.length; i++) {
      if (i > 0 && data[i]['points'] == data[i - 1]['points']) {
        data[i]['rank'] = data[i - 1]['rank'];
      } else {
        data[i]['rank'] = i + 1;
      }
    }

    _leaderboardData = data;
    _userIndexInList = _leaderboardData.indexWhere((d) => d['uid'] == currentUid);
    _usingMockData = false;
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryNavy,
      elevation: 0,
      leading: const BackButton(color: Colors.white),
      actions: [
        TextButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.leaderboardDemo),
          child: const Text(
            'DEMO',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.2),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          context.tr('leaderboard'),
          style: GoogleFonts.playfairDisplay(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.navyGradient,
          ),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Icon(Icons.stars, size: 150, color: Colors.white.withOpacity(0.05)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumSection(String? currentUid) {
    if (_leaderboardData.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    final podiumCount = _leaderboardData.length.clamp(0, 3);
    
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        decoration: const BoxDecoration(
          color: AppTheme.primaryNavy,
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (podiumCount >= 2) 
              _podiumItem(_leaderboardData[1], 2, 140, currentUid),
            _podiumItem(_leaderboardData[0], 1, 180, currentUid),
            if (podiumCount >= 3) 
              _podiumItem(_leaderboardData[2], 3, 120, currentUid)
            else if (podiumCount > 0)
              const SizedBox(width: 80), // Placeholder to keep center item centered
          ],
        ),
      ),
    );
  }

  Widget _podiumItem(Map<String, dynamic> user, int rank, double height, String? currentUid) {
    final bool isCurrentUser = user['uid'] == currentUid;
    final String name = user['name'] ?? 'Student';
    final int points = user['points'] ?? 0;
    final avatarChar = name.isNotEmpty ? name[0].toUpperCase() : '?';

    String crownEmoji = '';
    if (rank == 1) crownEmoji = '👑';
    else if (rank == 2) crownEmoji = '🥈';
    else if (rank == 3) crownEmoji = '🥉';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (rank == 1) Text(crownEmoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Container(
          width: rank == 1 ? 80 : 70,
          height: rank == 1 ? 80 : 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: rank == 1 ? const Color(0xFFFFD700) : (isCurrentUser ? AppTheme.accentBlue : Colors.white24),
              width: 3,
            ),
            boxShadow: rank == 1 
              ? [BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)] 
              : (isCurrentUser ? AppTheme.elevatedShadow : null),
          ),
          child: CircleAvatar(
            backgroundColor: rank == 1 ? const Color(0xFFFFD700) : (isCurrentUser ? AppTheme.accentBlue : AppTheme.darkCard),
            child: Text(
              avatarChar,
              style: GoogleFonts.playfairDisplay(
                fontSize: rank == 1 ? 32 : 28,
                fontWeight: FontWeight.bold,
                color: rank == 1 ? AppTheme.primaryNavy : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 85,
          height: height,
          decoration: BoxDecoration(
            gradient: rank == 1 ? royalGoldGradient : (isCurrentUser ? AppTheme.primaryGradient : AppTheme.navyGradient),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: GoogleFonts.playfairDisplay(
                  color: rank == 1 ? AppTheme.primaryNavy : Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: rank == 1 ? 24 : 20,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  isCurrentUser ? context.tr('you') : name.split(' ')[0],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: rank == 1 ? AppTheme.primaryNavy : Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rank == 1 ? AppTheme.primaryNavy.withOpacity(0.1) : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$points',
                  style: TextStyle(
                    color: rank == 1 ? AppTheme.primaryNavy : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankList(String? currentUid) {
    if (_leaderboardData.length <= 3) return const SliverToBoxAdapter(child: SizedBox.shrink());
    
    final listItems = _leaderboardData.sublist(3);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final user = listItems[index];
            return _buildRankItem(user, currentUid);
          },
          childCount: listItems.length,
        ),
      ),
    );
  }

  Widget _buildRankItem(Map<String, dynamic> user, String? currentUid) {
    final bool isCurrentUser = user['uid'] == currentUid;
    final int rank = user['rank'];
    final String name = user['name'] ?? 'Student';
    final int points = user['points'] ?? 0;

    String rankEmoji = '🚀'; 
    if (points >= 500) rankEmoji = '💎';
    else if (points >= 200) rankEmoji = '🔥';
    else if (rank <= 10) rankEmoji = '⭐';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardBoxShadow,
        border: isCurrentUser ? Border.all(color: AppTheme.accentBlue.withOpacity(0.5), width: 1.5) : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: SizedBox(
          width: 60,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#$rank',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(width: 4),
              Text(rankEmoji, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        title: Text(
          isCurrentUser ? '${context.tr('you')} ($name)' : name,
          style: GoogleFonts.inter(
            fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
            color: isCurrentUser ? AppTheme.accentBlue : AppTheme.textPrimary,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$points',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppTheme.primaryNavy,
              ),
            ),
            Text(
              'XP',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedUserCard(Map<String, dynamic> user, String? currentUid) {
    final int rank = user['rank'] ?? 0;
    final int points = user['points'] ?? 0;
    final String name = user['name'] ?? 'You';

    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                '#$rank',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.tr('your_ranking'),
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                  Text(
                    name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$points',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20),
                ),
                const Text(
                  'XP',
                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: AppTheme.errorRed.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(context.tr('leaderboard_unavailable'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              context.tr('network_error_msg'),
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.tr('retry')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events_outlined, size: 100, color: AppTheme.textLight.withOpacity(0.2)),
          const SizedBox(height: 24),
          Text(
            context.tr('no_leaderboard_data_yet'),
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('start_studying_to_earn_points'),
            style: TextStyle(color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }
}
