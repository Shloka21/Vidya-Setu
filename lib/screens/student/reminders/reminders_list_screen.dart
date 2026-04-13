import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../app/routes.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../models/reminder_model.dart';
import '../../../widgets/common/app_card.dart';
import 'package:vidyasetu/services/localization_service.dart';

class RemindersListScreen extends StatefulWidget {
  const RemindersListScreen({super.key});

  @override
  State<RemindersListScreen> createState() => _RemindersListScreenState();
}

class _RemindersListScreenState extends State<RemindersListScreen> {
  final FirestoreService _firestore = FirestoreService();
  String _selectedFilter = 'All';

  final _filters = ['All', 'Today', 'Upcoming', 'Completed'];

  bool _matchesFilter(ReminderModel r) {
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'Today':
        return r.dateTime.year == now.year &&
            r.dateTime.month == now.month &&
            r.dateTime.day == now.day;
      case 'Upcoming':
        return r.status != ReminderStatus.completed && r.dateTime.isAfter(now);
      case 'Completed':
        return r.status == ReminderStatus.completed;
      default:
        return true;
    }
  }

  Map<String, int> _categoryCounts(List<ReminderModel> all) {
    final counts = <String, int>{
      'Exams': 0,
      'Assignments': 0,
      'Quizzes': 0,
      'Study': 0,
    };
    for (var r in all) {
      switch (r.type) {
        case ReminderType.exam:
          counts['Exams'] = counts['Exams']! + 1;
          break;
        case ReminderType.assignment:
          counts['Assignments'] = counts['Assignments']! + 1;
          break;
        case ReminderType.quiz:
          counts['Quizzes'] = counts['Quizzes']! + 1;
          break;
        case ReminderType.studySession:
          counts['Study'] = counts['Study']! + 1;
          break;
        default:
          break;
      }
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<AuthProvider>(context).userModel?.uid;
    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(context.tr('please_log_in'))),
      );
    }

    return Scaffold(
      
      appBar: AppBar(title: Text(context.tr('reminders'))),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addReminder),
        backgroundColor: AppTheme.primaryNavy,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.remindersStream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allReminders = (snapshot.data?.docs ?? []).map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ReminderModel.fromMap({...data, 'id': doc.id});
          }).toList();

          // Auto-delete expired one-time reminders (5+ min past their time)
          final now = DateTime.now();
          final expiredIds = <String>[];
          for (final r in allReminders) {
            if (r.repeatType == 'once' &&
                r.status != ReminderStatus.completed &&
                r.dateTime.isBefore(now.subtract(const Duration(minutes: 5)))) {
              expiredIds.add(r.id);
            }
          }
          if (expiredIds.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              for (final id in expiredIds) {
                _firestore.deleteReminder(uid, id);
              }
            });
          }

          // Remove expired from local list so they vanish immediately
          allReminders.removeWhere((r) => expiredIds.contains(r.id));

          allReminders.sort((a, b) => a.dateTime.compareTo(b.dateTime));
          final filtered = allReminders.where(_matchesFilter).toList();
          final counts = _categoryCounts(allReminders);

          return Column(
            children: [
              // Filter chips
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedFilter = filter),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primaryNavy : AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: isSelected ? null : Border.all(color: AppTheme.divider),
                          ),
                          child: Text(
                            filter,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Category badges
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: Row(
                  children: counts.entries.map((entry) {
                    return Expanded(
                      child: _buildCategoryBadge(entry.key, entry.value),
                    );
                  }).toList(),
                ),
              ),

              // Reminders list
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_off_rounded, size: 56, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5).withValues(alpha: 0.4)),
                            SizedBox(height: 12),
                            Text(
                              context.tr('no_reminders_in_this_view'),
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 4),
                            Text(
                              context.tr('tap_the__button_to_add_a_reminder'),
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _buildReminderCard(uid, filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryBadge(String label, int count) {
    final colors = {
      'Exams': AppTheme.errorRed,
      'Assignments': AppTheme.accentBlue,
      'Quizzes': AppTheme.accentPurple,
      'Study': AppTheme.successGreen,
    };
    final color = colors[label] ?? Theme.of(context).colorScheme.onSurface.withOpacity(0.7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(color: color, fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(String uid, ReminderModel reminder) {
    final isDone = reminder.status == ReminderStatus.completed;
    final timeStr = DateFormat('MMM d, h:mm a').format(reminder.dateTime);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(reminder.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppTheme.errorRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed, size: 28),
        ),
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(context.tr('delete_reminder')),
              content: Text(context.tr('delete_1') + ' "${reminder.title}"?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(context.tr('delete'), style: TextStyle(color: AppTheme.errorRed)),
                ),
              ],
            ),
          ) ?? false;
        },
        onDismissed: (_) => _firestore.deleteReminder(uid, reminder.id),
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: reminder.priorityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _typeIcon(reminder.type),
                      color: reminder.priorityColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: TextStyle(
                            color: isDone ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Theme.of(context).colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: isDone ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: reminder.priorityColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                reminder.typeLabel,
                                style: TextStyle(
                                  color: reminder.priorityColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.access_time_rounded, size: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Priority dot
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: reminder.priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  reminder.description!,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextButton.icon(
                        onPressed: () => _toggleDone(uid, reminder),
                        icon: Icon(
                          isDone ? Icons.undo_rounded : Icons.check_circle_outline_rounded,
                          size: 18,
                        ),
                        label: Text(isDone ? 'Undo' : 'Done', style: const TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(
                          foregroundColor: isDone ? AppTheme.warningAmber : AppTheme.successGreen,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          AppRoutes.editReminder,
                          arguments: reminder,
                        ),
                        icon: Icon(Icons.edit_outlined, size: 18),
                        label: Text(context.tr('edit'), style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.accentBlue,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextButton.icon(
                        onPressed: () => _deleteReminder(uid, reminder),
                        icon: Icon(Icons.delete_outline_rounded, size: 18),
                        label: Text(context.tr('delete'), style: TextStyle(fontSize: 13)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.errorRed,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(ReminderType type) {
    switch (type) {
      case ReminderType.exam: return Icons.quiz_rounded;
      case ReminderType.assignment: return Icons.assignment_rounded;
      case ReminderType.quiz: return Icons.question_answer_rounded;
      case ReminderType.studySession: return Icons.menu_book_rounded;
      case ReminderType.custom: return Icons.event_rounded;
    }
  }

  Future<void> _toggleDone(String uid, ReminderModel reminder) async {
    final newStatus = reminder.status == ReminderStatus.completed
        ? ReminderStatus.pending
        : ReminderStatus.completed;

    final updates = <String, dynamic>{'status': newStatus.name};

    if (newStatus == ReminderStatus.completed) {
      // Store when it was completed for auto-delete
      updates['completedAt'] = DateTime.now().toIso8601String();

      // Auto-delete after 10 minutes
      Future.delayed(const Duration(minutes: 10), () async {
        try {
          await _firestore.deleteReminder(uid, reminder.id);
        } catch (_) {}
      });
    } else {
      updates['completedAt'] = null;
    }

    await _firestore.updateReminder(uid, reminder.id, updates);
  }

  Future<void> _deleteReminder(String uid, ReminderModel reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(context.tr('delete_reminder')),
        content: Text(context.tr('delete_1') + ' "${reminder.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('delete'), style: TextStyle(color: AppTheme.errorRed)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _firestore.deleteReminder(uid, reminder.id);
    }
  }
}

