import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../widgets/common/app_card.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _weeklyData = [
    {'rank': 1, 'name': 'Priya Singh', 'xp': 520, 'level': 8, 'streak': 14},
    {'rank': 2, 'name': 'Ananya Kumar', 'xp': 480, 'level': 7, 'streak': 12},
    {'rank': 3, 'name': 'Vikram Sharma', 'xp': 420, 'level': 7, 'streak': 9},
    {'rank': 4, 'name': 'Raj Patel', 'xp': 380, 'level': 6, 'streak': 7},
    {'rank': 5, 'name': 'Neha Gupta', 'xp': 350, 'level': 6, 'streak': 11},
    {'rank': 6, 'name': 'Aditya Joshi', 'xp': 310, 'level': 5, 'streak': 5},
    {'rank': 7, 'name': 'Meera Iyer', 'xp': 290, 'level': 5, 'streak': 8},
    {'rank': 8, 'name': 'Rohit Das', 'xp': 260, 'level': 4, 'streak': 3},
    {'rank': 9, 'name': 'Kavya Reddy', 'xp': 240, 'level': 4, 'streak': 6},
    {'rank': 10, 'name': 'Arjun Nair', 'xp': 220, 'level': 4, 'streak': 4},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          tabs: const [
            Tab(text: 'Weekly'),
            Tab(text: 'Monthly'),
            Tab(text: 'All Time'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLeaderboard(),
          _buildLeaderboard(),
          _buildLeaderboard(),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Top 3 podium
          SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _podiumItem(_weeklyData[1], 2, 140),
                _podiumItem(_weeklyData[0], 1, 180),
                _podiumItem(_weeklyData[2], 3, 110),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Rest of the list
          ...List.generate(
            _weeklyData.length - 3,
            (i) => _rankItem(_weeklyData[i + 3]),
          ),
        ],
      ),
    );
  }

  Widget _podiumItem(Map<String, dynamic> user, int position, double height) {
    final colors = {
      1: const Color(0xFFFFD700),
      2: const Color(0xFFC0C0C0),
      3: const Color(0xFFCD7F32),
    };
    final medals = {1: '🥇', 2: '🥈', 3: '🥉'};

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
              border: Border.all(color: colors[position]!, width: 3),
            ),
            child: Center(
              child: Text(
                (user['name'] as String)[0],
                style: TextStyle(
                    color: colors[position],
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            (user['name'] as String).split(' ')[0],
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          Text('${user['xp']} XP',
              style: TextStyle(
                  color: AppTheme.accentBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: height - 100,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colors[position]!.withOpacity(0.3),
                  colors[position]!.withOpacity(0.1),
                ],
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Text('#$position',
                  style: TextStyle(
                      color: colors[position],
                      fontSize: 20,
                      fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rankItem(Map<String, dynamic> user) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#${user['rank']}',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 15,
                    fontWeight: FontWeight.w700),
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (user['name'] as String)[0],
                  style: TextStyle(
                      color: AppTheme.accentBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user['name'] as String,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  Text('Level ${user['level']} • 🔥 ${user['streak']}d streak',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accentPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${user['xp']} XP',
                  style: TextStyle(
                      color: AppTheme.accentPurple,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
