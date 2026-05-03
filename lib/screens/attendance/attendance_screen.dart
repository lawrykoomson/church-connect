import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../models/attendance_model.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _memberId = '';
  String _memberName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMemberDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMemberDetails() async {
    final uid = _auth.currentUser!.uid;
    final doc = await _firestore
        .collection(AppConstants.membersCollection)
        .doc(uid)
        .get();
    if (doc.exists) {
      setState(() {
        _memberId = uid;
        _memberName = doc.data()!['fullName'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _auth.currentUser?.email == AppConstants.adminEmail;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Services'),
            Tab(text: 'My Attendance'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1 — Services list
          _ServicesTab(
            isAdmin: isAdmin,
            firestore: _firestore,
            memberId: _memberId,
            memberName: _memberName,
          ),
          // Tab 2 — My attendance record
          _MyAttendanceTab(
            firestore: _firestore,
            memberId: _memberId,
            memberName: _memberName,
          ),
        ],
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => _showMarkAttendanceDialog(context),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.how_to_reg, color: Colors.white),
              label: const Text(
                'Mark Attendance',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }

  void _showMarkAttendanceDialog(BuildContext context) async {
    // Get all members
    final membersSnap = await _firestore
        .collection(AppConstants.membersCollection)
        .orderBy('fullName')
        .get();

    final allMembers = membersSnap.docs.map((doc) {
      return {
        'id': doc.id,
        'name': doc.data()['fullName'] ?? '',
        'dept': doc.data()['department'] ?? '',
      };
    }).toList();

    final presentIds = <String>{};
    final titleController = TextEditingController(text: 'Sunday Service');
    String serviceType = 'Sunday Service';
    DateTime serviceDate = DateTime.now();

    final serviceTypes = [
      'Sunday Service',
      'Wednesday Bible Study',
      'Friday Prayer',
      'Special Service',
      'Youth Service',
      'Children Service',
    ];

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Mark Attendance',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 500,
            child: Column(
              children: [
                // Service type
                DropdownButtonFormField<String>(
                  value: serviceType,
                  decoration: InputDecoration(
                    labelText: 'Service Type',
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: serviceTypes
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text(s),
                          ))
                      .toList(),
                  onChanged: (val) {
                    setState(() {
                      serviceType = val!;
                      titleController.text = val;
                    });
                  },
                ),
                const SizedBox(height: 10),

                // Date picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: serviceDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => serviceDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd MMM yyyy').format(serviceDate),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Members present
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Present: ${presentIds.length}/${allMembers.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          if (presentIds.length == allMembers.length) {
                            presentIds.clear();
                          } else {
                            presentIds.addAll(
                              allMembers.map((m) => m['id'] as String),
                            );
                          }
                        });
                      },
                      child: Text(
                        presentIds.length == allMembers.length
                            ? 'Deselect All'
                            : 'Select All',
                      ),
                    ),
                  ],
                ),

                // Members checklist
                Expanded(
                  child: ListView.builder(
                    itemCount: allMembers.length,
                    itemBuilder: (context, index) {
                      final member = allMembers[index];
                      final membId = member['id'] as String;
                      final isPresent = presentIds.contains(membId);
                      return CheckboxListTile(
                        value: isPresent,
                        activeColor: AppColors.primary,
                        title: Text(
                          member['name'] as String,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: Text(
                          member['dept'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textGrey,
                          ),
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              presentIds.add(membId);
                            } else {
                              presentIds.remove(membId);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _firestore.collection('attendance').add({
                  'serviceTitle': serviceType,
                  'serviceDate': DateFormat('yyyy-MM-dd').format(serviceDate),
                  'serviceType': serviceType,
                  'presentMembers': presentIds.toList(),
                  'markedBy': AppConstants.pastorName,
                  'createdAt': DateTime.now().toIso8601String(),
                });

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Attendance marked — ${presentIds.length} members present.',
                      ),
                      backgroundColor: AppColors.paid,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Save Attendance'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Services Tab ──
class _ServicesTab extends StatelessWidget {
  final bool isAdmin;
  final FirebaseFirestore firestore;
  final String memberId;
  final String memberName;

  const _ServicesTab({
    required this.isAdmin,
    required this.firestore,
    required this.memberId,
    required this.memberName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('attendance')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No attendance records yet.',
              style: TextStyle(color: AppColors.textGrey),
            ),
          );
        }

        final records = snapshot.data!.docs.map((doc) {
          return AttendanceRecord.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: records.length,
          itemBuilder: (context, index) {
            final record = records[index];
            final isPresent = record.presentMembers.contains(memberId);
            return FadeInUp(
              delay: Duration(milliseconds: index * 80),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.church,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            record.serviceTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy').format(
                              DateTime.parse(record.serviceDate),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textGrey,
                            ),
                          ),
                          Text(
                            '${record.presentMembers.length} members present',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPresent
                            ? AppColors.paid.withOpacity(0.1)
                            : AppColors.overdue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isPresent ? '✅ Present' : '❌ Absent',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPresent ? AppColors.paid : AppColors.overdue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── My Attendance Tab ──
class _MyAttendanceTab extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String memberId;
  final String memberName;

  const _MyAttendanceTab({
    required this.firestore,
    required this.memberId,
    required this.memberName,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('attendance')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          );
        }

        final allRecords = snapshot.data!.docs.map((doc) {
          return AttendanceRecord.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        final totalServices = allRecords.length;
        final attended =
            allRecords.where((r) => r.presentMembers.contains(memberId)).length;
        final percentage = totalServices > 0
            ? (attended / totalServices * 100).toStringAsFixed(1)
            : '0.0';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Stats card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      value: '$totalServices',
                      label: 'Total Services',
                    ),
                    _StatItem(
                      value: '$attended',
                      label: 'Attended',
                    ),
                    _StatItem(
                      value: '$percentage%',
                      label: 'Attendance Rate',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Attendance list
              ...allRecords.map((record) {
                final isPresent = record.presentMembers.contains(memberId);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPresent
                          ? AppColors.paid.withOpacity(0.3)
                          : AppColors.overdue.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isPresent ? Icons.check_circle : Icons.cancel,
                        color: isPresent ? AppColors.paid : AppColors.overdue,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              record.serviceTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              DateFormat('dd MMM yyyy').format(
                                DateTime.parse(record.serviceDate),
                              ),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        isPresent ? 'Present' : 'Absent',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isPresent ? AppColors.paid : AppColors.overdue,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
