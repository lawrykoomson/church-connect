import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../models/member_model.dart';
import '../../services/sms_service.dart';

class SmsScreen extends StatefulWidget {
  const SmsScreen({super.key});

  @override
  State<SmsScreen> createState() => _SmsScreenState();
}

class _SmsScreenState extends State<SmsScreen>
    with SingleTickerProviderStateMixin {
  final _smsService = SmsService();
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'SMS Alerts',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.secondary,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF888888),
          tabs: const [
            Tab(text: 'Overdue'),
            Tab(text: 'Events'),
            Tab(text: 'Custom'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _OverdueSmsTab(smsService: _smsService),
          _EventSmsTab(smsService: _smsService),
          _CustomSmsTab(smsService: _smsService),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// TAB 1 — Overdue Reminders
// ══════════════════════════════════════════════
class _OverdueSmsTab extends StatefulWidget {
  final SmsService smsService;
  const _OverdueSmsTab({required this.smsService});

  @override
  State<_OverdueSmsTab> createState() => _OverdueSmsTabState();
}

class _OverdueSmsTabState extends State<_OverdueSmsTab> {
  final _firestore = FirebaseFirestore.instance;
  List<Member> _overdueMembers = [];
  Set<String> _selectedIds = {};
  bool _isLoading = false;
  bool _isSending = false;
  Map<String, bool> _sendResults = {};

  @override
  void initState() {
    super.initState();
    _loadOverdueMembers();
  }

  Future<void> _loadOverdueMembers() async {
    setState(() => _isLoading = true);
    final snap = await _firestore
        .collection(AppConstants.membersCollection)
        .where('duesStatus', isEqualTo: AppConstants.statusOverdue)
        .get();
    setState(() {
      _overdueMembers = snap.docs
          .map((doc) => Member.fromFirestore(doc.data(), doc.id))
          .toList();
      _isLoading = false;
    });
  }

  Future<void> _sendReminders() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    final selected =
        _overdueMembers.where((m) => _selectedIds.contains(m.id)).toList();

    Map<String, bool> results = {};
    for (final member in selected) {
      final message = widget.smsService.overdueReminderMessage(
        memberName: member.fullName,
        amountOutstanding: member.amountOutstanding,
      );
      final success = await widget.smsService.sendSms(
        phoneNumber: member.phoneNumber,
        message: message,
      );
      results[member.id] = success;
    }

    setState(() {
      _isSending = false;
      _sendResults = results;
    });

    final successCount = results.values.where((v) => v).length;

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$successCount of ${selected.length} SMS sent successfully!',
          ),
          backgroundColor: AppColors.paid,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.secondary,
        ),
      );
    }

    if (_overdueMembers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: AppColors.paid,
            ),
            const SizedBox(height: 16),
            const Text(
              'No overdue members!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.paid,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All members are up to date.',
              style: TextStyle(color: AppColors.textGrey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // ── Header ──
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_overdueMembers.length} overdue members found',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.overdue,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedIds.length == _overdueMembers.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds = _overdueMembers.map((m) => m.id).toSet();
                    }
                  });
                },
                child: Text(
                  _selectedIds.length == _overdueMembers.length
                      ? 'Deselect All'
                      : 'Select All',
                  style: const TextStyle(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Members List ──
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _overdueMembers.length,
            itemBuilder: (context, index) {
              final member = _overdueMembers[index];
              final isSelected = _selectedIds.contains(member.id);
              final wasSent = _sendResults[member.id];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.overdue.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? AppColors.overdue : AppColors.border,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      activeColor: AppColors.overdue,
                      onChanged: (_) {
                        setState(() {
                          if (isSelected) {
                            _selectedIds.remove(member.id);
                          } else {
                            _selectedIds.add(member.id);
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            member.phoneNumber,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ),
                          Text(
                            'GHS ${member.amountOutstanding.toStringAsFixed(2)} outstanding',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.overdue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (wasSent != null)
                      Icon(
                        wasSent ? Icons.check_circle : Icons.error_outline,
                        color: wasSent ? AppColors.paid : AppColors.error,
                        size: 22,
                      ),
                  ],
                ),
              );
            },
          ),
        ),

        // ── Send Button ──
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendReminders,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.overdue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSending
                    ? 'Sending...'
                    : 'Send Reminders (${_selectedIds.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════
// TAB 2 — Event Announcements
// ══════════════════════════════════════════════
class _EventSmsTab extends StatefulWidget {
  final SmsService smsService;
  const _EventSmsTab({required this.smsService});

  @override
  State<_EventSmsTab> createState() => _EventSmsTabState();
}

class _EventSmsTabState extends State<_EventSmsTab> {
  final _firestore = FirebaseFirestore.instance;
  String? _selectedEventId;
  String? _selectedEventTitle;
  String? _selectedEventDate;
  String? _selectedEventLocation;
  List<Map<String, dynamic>> _events = [];
  bool _isSending = false;
  bool _isLoadingEvents = false;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() => _isLoadingEvents = true);
    final snap = await _firestore
        .collection(AppConstants.eventsCollection)
        .orderBy('date')
        .get();
    setState(() {
      _events = snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'title': data['title'] ?? '',
          'date': data['date'] ?? '',
          'location': data['location'] ?? '',
        };
      }).toList();
      _isLoadingEvents = false;
    });
  }

  Future<void> _sendEventAnnouncements() async {
    if (_selectedEventId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an event.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    // Get all members
    final snap =
        await _firestore.collection(AppConstants.membersCollection).get();
    final members = snap.docs
        .map((doc) => Member.fromFirestore(doc.data(), doc.id))
        .toList();

    int successCount = 0;
    for (final member in members) {
      final message = widget.smsService.eventAnnouncementMessage(
        memberName: member.fullName,
        eventTitle: _selectedEventTitle!,
        eventDate: _selectedEventDate!,
        location: _selectedEventLocation ?? 'Church Premises',
      );
      final success = await widget.smsService.sendSms(
        phoneNumber: member.phoneNumber,
        message: message,
      );
      if (success) successCount++;
    }

    setState(() => _isSending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$successCount of ${members.length} members notified!',
          ),
          backgroundColor: AppColors.paid,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.secondary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: AppColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'This will send an SMS announcement to ALL members about the selected event.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Select event
          const Text(
            'Select Event',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedEventId,
                isExpanded: true,
                hint: const Text(
                  'Choose an event',
                  style: TextStyle(color: AppColors.textLight),
                ),
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.primary,
                ),
                items: _events.map((event) {
                  return DropdownMenuItem<String>(
                    value: event['id'],
                    child: Text(event['title']),
                  );
                }).toList(),
                onChanged: (val) {
                  final selected = _events.firstWhere((e) => e['id'] == val);
                  final date = DateTime.parse(selected['date']);
                  setState(() {
                    _selectedEventId = val;
                    _selectedEventTitle = selected['title'];
                    _selectedEventDate =
                        DateFormat('dd MMM yyyy, h:mm a').format(date);
                    _selectedEventLocation = selected['location'];
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Preview message
          if (_selectedEventId != null) ...[
            const Text(
              'Message Preview',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F7FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.2),
                ),
              ),
              child: Text(
                widget.smsService.eventAnnouncementMessage(
                  memberName: '[Member Name]',
                  eventTitle: _selectedEventTitle!,
                  eventDate: _selectedEventDate!,
                  location: _selectedEventLocation ?? 'Church Premises',
                ),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDark,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Send button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendEventAnnouncements,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.campaign),
              label: Text(
                _isSending
                    ? 'Sending to all members...'
                    : 'Send to All Members',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// TAB 3 — Custom SMS
// ══════════════════════════════════════════════
class _CustomSmsTab extends StatefulWidget {
  final SmsService smsService;
  const _CustomSmsTab({required this.smsService});

  @override
  State<_CustomSmsTab> createState() => _CustomSmsTabState();
}

class _CustomSmsTabState extends State<_CustomSmsTab> {
  final _firestore = FirebaseFirestore.instance;
  final _messageController = TextEditingController();
  List<Member> _members = [];
  Set<String> _selectedIds = {};
  bool _isSending = false;
  bool _sendToAll = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    final snap =
        await _firestore.collection(AppConstants.membersCollection).get();
    setState(() {
      _members = snap.docs
          .map((doc) => Member.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> _sendCustomSms() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final targets = _sendToAll
        ? _members
        : _members.where((m) => _selectedIds.contains(m.id)).toList();

    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one member.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    int successCount = 0;
    for (final member in targets) {
      final success = await widget.smsService.sendSms(
        phoneNumber: member.phoneNumber,
        message: _messageController.text.trim(),
      );
      if (success) successCount++;
    }

    setState(() => _isSending = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$successCount of ${targets.length} SMS sent!',
          ),
          backgroundColor: AppColors.paid,
        ),
      );
      _messageController.clear();
      setState(() => _selectedIds.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message field
          const Text(
            'Your Message',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _messageController,
            maxLines: 4,
            maxLength: 160,
            decoration: InputDecoration(
              hintText: 'Type your message here...',
              hintStyle: const TextStyle(
                color: AppColors.textLight,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.secondary,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Send to all toggle
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text(
                  'Send to All Members',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: _sendToAll,
                  activeThumbColor: AppColors.secondary,
                  onChanged: (val) => setState(() => _sendToAll = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Individual member selection
          if (!_sendToAll) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Members',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedIds.length == _members.length) {
                        _selectedIds.clear();
                      } else {
                        _selectedIds = _members.map((m) => m.id).toSet();
                      }
                    });
                  },
                  child: const Text(
                    'Select All',
                    style: TextStyle(
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ..._members.map((member) {
              final isSelected = _selectedIds.contains(member.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.05)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      activeColor: AppColors.primary,
                      onChanged: (_) {
                        setState(() {
                          if (isSelected) {
                            _selectedIds.remove(member.id);
                          } else {
                            _selectedIds.add(member.id);
                          }
                        });
                      },
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            member.phoneNumber,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
          ],

          // Send button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: _isSending ? null : _sendCustomSms,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send),
              label: Text(
                _isSending ? 'Sending...' : 'Send SMS',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
