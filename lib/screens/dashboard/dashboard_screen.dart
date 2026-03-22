import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  int _totalMembers = 0;
  int _paidMembers = 0;
  int _overdueMembers = 0;
  int _pendingMembers = 0;
  int _totalEvents = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load members stats
      final membersSnap =
          await _firestore.collection(AppConstants.membersCollection).get();

      int paid = 0;
      int overdue = 0;
      int pending = 0;

      for (var doc in membersSnap.docs) {
        final status = doc.data()['duesStatus'] ?? '';
        if (status == AppConstants.statusPaid) paid++;
        if (status == AppConstants.statusOverdue) overdue++;
        if (status == AppConstants.statusPending) pending++;
      }

      // Load events count
      final eventsSnap =
          await _firestore.collection(AppConstants.eventsCollection).get();

      setState(() {
        _totalMembers = membersSnap.docs.length;
        _paidMembers = paid;
        _overdueMembers = overdue;
        _pendingMembers = pending;
        _totalEvents = eventsSnap.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.church,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              AppConstants.appName,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadDashboardData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.secondary,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              color: AppColors.secondary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Welcome Banner ──
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            Color(0xFF2C3E50),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back, Admin 👋',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'You have $_overdueMembers overdue dues to follow up on.',
                            style: const TextStyle(
                              color: Color(0xFFCCCCCC),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Section title ──
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Stats Grid ──
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: [
                        _StatCard(
                          title: 'Total Members',
                          value: '$_totalMembers',
                          icon: Icons.people,
                          color: AppColors.primary,
                        ),
                        _StatCard(
                          title: 'Dues Paid',
                          value: '$_paidMembers',
                          icon: Icons.check_circle,
                          color: AppColors.paid,
                        ),
                        _StatCard(
                          title: 'Overdue',
                          value: '$_overdueMembers',
                          icon: Icons.warning_amber,
                          color: AppColors.overdue,
                        ),
                        _StatCard(
                          title: 'Pending',
                          value: '$_pendingMembers',
                          icon: Icons.hourglass_empty,
                          color: AppColors.pending,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Quick Actions ──
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.6,
                      children: [
                        _ActionCard(
                          title: 'Members',
                          subtitle: 'Manage database',
                          icon: Icons.people_alt,
                          color: AppColors.primary,
                          onTap: () => Navigator.pushNamed(context, '/members'),
                        ),
                        _ActionCard(
                          title: 'Payments',
                          subtitle: 'Record dues',
                          icon: Icons.payments,
                          color: AppColors.paid,
                          onTap: () =>
                              Navigator.pushNamed(context, '/payments'),
                        ),
                        _ActionCard(
                          title: 'Events',
                          subtitle: 'Manage events',
                          icon: Icons.event,
                          color: AppColors.secondary,
                          onTap: () => Navigator.pushNamed(context, '/events'),
                        ),
                        _ActionCard(
                          title: 'Reports',
                          subtitle: 'View analytics',
                          icon: Icons.bar_chart,
                          color: Color(0xFF8E44AD),
                          onTap: () => Navigator.pushNamed(context, '/reports'),
                        ),
                        _ActionCard(
                          title: 'SMS Alerts',
                          subtitle: 'Send messages',
                          icon: Icons.sms,
                          color: const Color(0xFF16A085),
                          onTap: () => Navigator.pushNamed(context, '/sms'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Recent Activity ──
                    const Text(
                      'Recent Members',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection(AppConstants.membersCollection)
                          .orderBy('createdAt', descending: true)
                          .limit(5)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.secondary,
                            ),
                          );
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'No members yet. Add your first member!',
                                style: TextStyle(
                                  color: AppColors.textGrey,
                                ),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final status = data['duesStatus'] ?? 'Pending';
                            return _MemberTile(
                              name: data['fullName'] ?? 'Unknown',
                              department: data['department'] ?? 'General',
                              status: status,
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }
}

// ══════════════════════════════════════════════
// STAT CARD WIDGET
// ══════════════════════════════════════════════
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════
// ACTION CARD WIDGET
// ══════════════════════════════════════════════
class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
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

// ══════════════════════════════════════════════
// MEMBER TILE WIDGET
// ══════════════════════════════════════════════
class _MemberTile extends StatelessWidget {
  final String name;
  final String department;
  final String status;

  const _MemberTile({
    required this.name,
    required this.department,
    required this.status,
  });

  Color get _statusColor {
    if (status == AppConstants.statusPaid) return AppColors.paid;
    if (status == AppConstants.statusOverdue) return AppColors.overdue;
    return AppColors.pending;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'M',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  department,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
