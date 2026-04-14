import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import '../../services/localization_service.dart';
import '../../app/theme.dart';

class LeaderboardDemoScreen extends StatefulWidget {
  const LeaderboardDemoScreen({super.key});

  @override
  State<LeaderboardDemoScreen> createState() => _LeaderboardDemoScreenState();
}

class _LeaderboardDemoScreenState extends State<LeaderboardDemoScreen> {
  final List<Map<String, dynamic>> _mockData = [];
  final ScrollController _scrollController = ScrollController();
  
  // Royal Gold Gradient for the Champion 👑
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
    _generateMockData();
  }

  void _generateMockData() {
    final List<String> firstNames = [
      'Shloka', 'Aman', 'Priya', 'Rahul', 'Sneha', 'Vikram', 'Ananya', 'Siddharth', 'Ishita', 'Arjun',
      'Zara', 'Leo', 'Mia', 'Noah', 'Ava', 'Ethan', 'Sophia', 'Lucas', 'Isabella', 'Mason',
      'Riya', 'Karan', 'Tanvi', 'Aditya', 'Sakshi', 'Rohan', 'Navya', 'Kabir', 'Myra', 'Aryan'
    ];
    final List<String> lastNames = ['Shetiya', 'Sharma', 'Patel', 'Verma', 'Gupta', 'Singh', 'Mehta', 'Joshi', 'Reddy', 'Nair'];

    final Random random = Random();

    // 1. Create a high-scoring Shloka for Rank #1 Demo
    _mockData.add({
      'uid': 'shloka_uid',
      'name': 'Shloka Shetiya',
      'points': 2850,
      'role': 'student',
      'rank': 1,
    });

    // 2. Generate 99 more students with descending points
    int currentPoints = 2700;
    for (int i = 2; i <= 100; i++) {
      currentPoints -= random.nextInt(40); // Gradual decrease
      if (currentPoints < 0) currentPoints = 0;

      final name = '${firstNames[random.nextInt(firstNames.length)]} ${lastNames[random.nextInt(lastNames.length)]}';
      
      _mockData.add({
        'uid': 'user_$i',
        'name': name,
        'points': currentPoints,
        'role': 'student',
        'rank': i,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildPodiumSection(),
              _buildRankList(),
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
          _buildPinnedUserCard(), // "Your" ranking spotlight
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryNavy,
      elevation: 0,
      leading: const BackButton(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Elite Leaderboard (Demo)',
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
                child: Icon(Icons.emoji_events, size: 150, color: Colors.white.withOpacity(0.05)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodiumSection() {
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
            _podiumItem(_mockData[1], 2, 140), // Rank 2
            _podiumItem(_mockData[0], 1, 180), // Rank 1
            _podiumItem(_mockData[2], 3, 120), // Rank 3
          ],
        ),
      ),
    );
  }

  Widget _podiumItem(Map<String, dynamic> user, int rank, double height) {
    final String name = user['name'];
    final int points = user['points'];
    final avatarChar = name[0].toUpperCase();

    String rankIcon = '';
    if (rank == 1) rankIcon = '👑';
    else if (rank == 2) rankIcon = '🥈';
    else if (rank == 3) rankIcon = '🥉';

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (rank == 1) Text(rankIcon, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Container(
          width: rank == 1 ? 85 : 70,
          height: rank == 1 ? 85 : 70,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: rank == 1 ? const Color(0xFFFFD700) : Colors.white24,
              width: 3,
            ),
            boxShadow: rank == 1 ? [
              BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.3), blurRadius: 20, spreadRadius: 2)
            ] : null,
          ),
          child: CircleAvatar(
            backgroundColor: rank == 1 ? const Color(0xFFFFD700) : AppTheme.darkCard,
            child: Text(
              avatarChar,
              style: GoogleFonts.playfairDisplay(
                fontSize: rank == 1 ? 36 : 28,
                fontWeight: FontWeight.bold,
                color: rank == 1 ? AppTheme.primaryNavy : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: rank == 1 ? 95 : 85,
          height: height,
          decoration: BoxDecoration(
            gradient: rank == 1 ? royalGoldGradient : AppTheme.navyGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
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
                  fontSize: rank == 1 ? 28 : 20,
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  name.split(' ')[0],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    color: rank == 1 ? AppTheme.primaryNavy : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: rank == 1 ? AppTheme.primaryNavy.withOpacity(0.1) : Colors.white.withOpacity(0.1),
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

  Widget _buildRankList() {
    final listItems = _mockData.sublist(3);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final user = listItems[index];
            return _buildRankItem(user);
          },
          childCount: listItems.length,
        ),
      ),
    );
  }

  Widget _buildRankItem(Map<String, dynamic> user) {
    final int rank = user['rank'];
    final String name = user['name'];
    final int points = user['points'];

    String rankEmoji = '🚀'; 
    if (points >= 2000) rankEmoji = '💎';
    else if (points >= 1000) rankEmoji = '🔥';
    else if (rank <= 10) rankEmoji = '⭐';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: AppTheme.cardBoxShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: SizedBox(
          width: 60,
          child: Row(
            children: [
              Text(
                '#$rank',
                style: GoogleFonts.playfairDisplay(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text(rankEmoji, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
        title: Text(
          name,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: (rank <= 10) ? Text('Top Elite', style: TextStyle(color: AppTheme.accentBlue, fontSize: 10, fontWeight: FontWeight.bold)) : null,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$points',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppTheme.primaryNavy,
              ),
            ),
            Text(
              'XP',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinnedUserCard() {
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          boxShadow: AppTheme.elevatedShadow,
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(
                '#1',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'YOU ARE THE CHAMPION!',
                    style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                  Text(
                    'Shloka Shetiya',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '2850',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22),
                ),
                Text(
                  'XP',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
