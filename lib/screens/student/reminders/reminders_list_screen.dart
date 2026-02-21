import 'package:flutter/material.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../widgets/common/app_card.dart';

class RemindersListScreen extends StatefulWidget {
  const RemindersListScreen({super.key});

  @override
  State<RemindersListScreen> createState() => _RemindersListScreenState();
}

class _RemindersListScreenState extends State<RemindersListScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Today', 'Upcoming', 'Completed'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reminders',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedFilter = filter),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor: Theme.of(context).colorScheme.onSurface,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Category counts
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildCategoryBadge('Exams', 2, AppTheme.errorRed),
                const SizedBox(width: 8),
                _buildCategoryBadge('Assignments', 3, AppTheme.warningAmber),
                const SizedBox(width: 8),
                _buildCategoryBadge('Quizzes', 1, AppTheme.accentBlue),
                const SizedBox(width: 8),
                _buildCategoryBadge('Study', 4, AppTheme.successGreen),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Reminders list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildReminderCard(
                  'Mathematics Final Exam',
                  'Exam',
                  'Feb 15, 10:00 AM',
                  'High',
                  'Chapters 1-5 including Integration and Differentiation',
                  AppTheme.errorRed,
                ),
                _buildReminderCard(
                  'Physics Assignment #3',
                  'Assignment',
                  'Feb 16, 5:00 PM',
                  'Medium',
                  'Newton\'s Laws of Motion - Problems 1-20',
                  AppTheme.warningAmber,
                ),
                _buildReminderCard(
                  'Chemistry Lab Report',
                  'Assignment',
                  'Feb 17, 11:59 PM',
                  'Medium',
                  'Titration experiment analysis and results',
                  AppTheme.warningAmber,
                ),
                _buildReminderCard(
                  'English Quiz',
                  'Quiz',
                  'Feb 18, 9:00 AM',
                  'Low',
                  'Shakespeare - Hamlet Act 3',
                  AppTheme.successGreen,
                ),
                _buildReminderCard(
                  'Biology Study Session',
                  'Study Session',
                  'Today, 8:00 PM',
                  'Medium',
                  'Cell Biology revision',
                  AppTheme.accentBlue,
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addReminder),
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryBadge(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(
    String title,
    String type,
    String dateTime,
    String priority,
    String description,
    Color priorityColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 50,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateTime,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppTheme.successGreen,
                  ),
                  label: Text(
                    'Done',
                    style: TextStyle(
                      color: AppTheme.successGreen,
                      fontSize: 13,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppTheme.accentBlue,
                  ),
                  label: Text(
                    'Edit',
                    style: TextStyle(color: AppTheme.accentBlue, fontSize: 13),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {},
                  icon: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppTheme.errorRed,
                  ),
                  label: Text(
                    'Delete',
                    style: TextStyle(color: AppTheme.errorRed, fontSize: 13),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
