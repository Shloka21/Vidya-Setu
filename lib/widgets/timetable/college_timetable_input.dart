import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../models/timetable_model.dart';

/// Interactive weekly grid for marking college lecture time slots.
/// Users tap cells to mark as busy (college), tap again to unmark.
class CollegeTimetableInput extends StatefulWidget {
  final List<CollegeSlot> slots;
  final ValueChanged<List<CollegeSlot>> onChanged;

  const CollegeTimetableInput({
    super.key,
    required this.slots,
    required this.onChanged,
  });

  @override
  State<CollegeTimetableInput> createState() => _CollegeTimetableInputState();
}

class _CollegeTimetableInputState extends State<CollegeTimetableInput> {
  // Grid: 6 days (Mon-Sat) × 11 hours (8AM-6PM)
  static const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  static const startHour = 8;
  static const endHour = 18; // 6PM

  late Set<String> _selected; // "weekday_hour" keys

  @override
  void initState() {
    super.initState();
    _selected = {};
    for (var slot in widget.slots) {
      for (int h = slot.startHour; h < slot.endHour; h++) {
        _selected.add('${slot.weekday}_$h');
      }
    }
  }

  void _toggleSlot(int weekday, int hour) {
    setState(() {
      final key = '${weekday}_$hour';
      if (_selected.contains(key)) {
        _selected.remove(key);
      } else {
        _selected.add(key);
      }
    });
    _notifyChange();
  }

  void _notifyChange() {
    // Convert selected set back to CollegeSlot list
    final slots = <CollegeSlot>[];
    for (int d = 1; d <= 6; d++) {
      int? slotStart;
      for (int h = startHour; h <= endHour; h++) {
        final key = '${d}_$h';
        if (_selected.contains(key)) {
          slotStart ??= h;
        } else if (slotStart != null) {
          slots.add(CollegeSlot(weekday: d, startHour: slotStart, endHour: h));
          slotStart = null;
        }
      }
      if (slotStart != null) {
        slots.add(CollegeSlot(
            weekday: d, startHour: slotStart, endHour: endHour));
      }
    }
    widget.onChanged(slots);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Row(
          children: [
            _legendDot(Colors.red.shade100, 'Busy (College)'),
            const SizedBox(width: 16),
            _legendDot(Colors.green.shade100, 'Free'),
          ],
        ),
        const SizedBox(height: 16),
        // Grid
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: 420,
            child: Column(
              children: [
                // Header row (hours)
                Row(
                  children: [
                    const SizedBox(width: 40), // Day label space
                    ...List.generate(endHour - startHour, (i) {
                      return SizedBox(
                        width: 38,
                        child: Text(
                          '${startHour + i}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 4),
                // Day rows
                ...List.generate(6, (dayIndex) {
                  final weekday = dayIndex + 1;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            days[dayIndex],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        ...List.generate(endHour - startHour, (hourIndex) {
                          final hour = startHour + hourIndex;
                          final key = '${weekday}_$hour';
                          final isSelected = _selected.contains(key);
                          return GestureDetector(
                            onTap: () => _toggleSlot(weekday, hour),
                            child: Container(
                              width: 36,
                              height: 32,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Colors.red.shade200
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.red.shade400
                                      : Colors.green.shade200,
                                  width: 1,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(Icons.school,
                                      size: 14, color: Colors.red.shade700)
                                  : null,
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap slots to mark college lectures. ${_selected.length} hours marked busy.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

