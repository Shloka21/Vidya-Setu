import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import 'package:vidyasetu/services/localization_service.dart';

class ScheduleGroupMeetingScreen extends StatefulWidget {
  const ScheduleGroupMeetingScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleGroupMeetingScreen> createState() => _ScheduleGroupMeetingScreenState();
}

class _ScheduleGroupMeetingScreenState extends State<ScheduleGroupMeetingScreen> {
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  final Set<String> _selectedStudentIds = {};
  bool _selectAll = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _scheduleMeeting() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('please_enter_meeting_title') ?? 'Please enter a title')));
      return;
    }
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('please_select_at_least_one_student') ?? 'Select at least one student')));
      return;
    }

    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final uid = auth.userModel?.uid ?? '';
    final firestore = FirestoreService();

    final scheduledAt = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
    
    try {
      // Create meeting doc
      final meetingId = FirebaseFirestore.instance.collection('_').doc().id;
      final participants = [uid, ..._selectedStudentIds.toList()];
      
      // Store group meeting
      await firestore.scheduleMeeting({
        'id': meetingId,
        'title': _titleController.text.trim(),
        'scheduledAt': Timestamp.fromDate(scheduledAt),
        'createdBy': uid,
        'participants': participants,
        'isGroup': true,
        'status': 'scheduled',
      });

      // Send a system message to each student's chat
      for (final studentId in _selectedStudentIds) {
        final roomId = await firestore.getOrCreateChatRoom(uid, studentId);
        final msgId = FirebaseFirestore.instance.collection('_').doc().id;
        await firestore.sendMessage(roomId, {
          'id': msgId,
          'content': '📅 Group Meeting Scheduled: ${_titleController.text.trim()} on ${DateFormat('MMM d').format(scheduledAt)} at ${_selectedTime.format(context)}',
          'senderId': uid,
          'receiverId': studentId,
          'timestamp': Timestamp.now(),
          'type': 'meeting',
          'scheduledAt': Timestamp.fromDate(scheduledAt),
          'meetingTitle': _titleController.text.trim(),
          'meetingId': meetingId,
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('meeting_scheduled') ?? 'Meeting scheduled successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('error_scheduling_meeting') ?? 'Error scheduling meeting')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<AuthProvider>(context, listen: false).userModel?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('schedule_group_meeting') ?? 'Group Meeting'),
        actions: [
          if (_isLoading) 
            const Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          if (!_isLoading)
            IconButton(icon: const Icon(Icons.check_rounded, color: AppTheme.successGreen), onPressed: _scheduleMeeting),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: context.tr('meeting_title'),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.calendar_today_rounded, color: AppTheme.accentBlue),
            title: Text(DateFormat('EEE, MMM d, yyyy').format(_selectedDate)),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          ListTile(
            leading: Icon(Icons.access_time_rounded, color: AppTheme.accentPurple),
            title: Text(_selectedTime.format(context)),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _selectedTime);
              if (picked != null) setState(() => _selectedTime = picked);
            },
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.tr('select_students') ?? 'Select Students', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Row(
                  children: [
                    Text(context.tr('select_all') ?? 'Select All', style: const TextStyle(fontSize: 14)),
                    Checkbox(
                      value: _selectAll,
                      activeColor: AppTheme.accentBlue,
                      onChanged: (val) {
                        setState(() {
                          _selectAll = val ?? false;
                          if (!_selectAll) {
                            _selectedStudentIds.clear();
                          }
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirestoreService().mentorConnectionsStream(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return Center(child: Text(context.tr('no_students_found') ?? 'No students connected'));
                
                // If Select All was just checked, add all IDs
                if (_selectAll && _selectedStudentIds.isEmpty && docs.isNotEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      for (var doc in docs) {
                        _selectedStudentIds.add((doc.data() as Map<String, dynamic>)['studentId'] as String);
                      }
                    });
                  });
                }
                
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final connData = docs[index].data() as Map<String, dynamic>;
                    final studentId = connData['studentId'] as String;
                    final studentName = connData['studentName'] as String? ?? 'Student';
                    
                    final isSelected = _selectedStudentIds.contains(studentId);
                    
                    return CheckboxListTile(
                      value: isSelected,
                      activeColor: AppTheme.accentBlue,
                      title: Text(studentName),
                      subtitle: Text(studentId, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedStudentIds.add(studentId);
                          } else {
                            _selectedStudentIds.remove(studentId);
                            _selectAll = false;
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
