import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';
import '../../models/prayer_model.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final _firestore    = FirebaseFirestore.instance;
  final _auth         = FirebaseAuth.instance;
  final _requestController = TextEditingController();
  String _selectedCategory = 'General';
  bool   _isAnonymous      = false;
  bool   _isLoading        = false;
  String _memberName       = '';
  String _memberEmail      = '';

  final List<String> _categories = [
    'General',
    'Healing',
    'Financial Breakthrough',
    'Family',
    'Career',
    'Spiritual Growth',
    'Thanksgiving',
  ];

  @override
  void initState() {
    super.initState();
    _loadMemberDetails();
  }

  @override
  void dispose() {
    _requestController.dispose();
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
        _memberName  = doc.data()!['fullName'] ?? '';
        _memberEmail = doc.data()!['email']    ?? '';
      });
    }
  }

  Future<void> _submitPrayer() async {
    if (_requestController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Please enter your prayer request.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firestore.collection('prayers').add({
        'memberName':  _isAnonymous ? 'Anonymous' : _memberName,
        'memberEmail': _memberEmail,
        'request':     _requestController.text.trim(),
        'category':    _selectedCategory,
        'status':      'Pending',
        'createdAt':   DateTime.now().toIso8601String(),
        'isAnonymous': _isAnonymous,
      });

      setState(() => _isLoading = false);
      _requestController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your prayer request has been submitted. We are praying with you!',
            ),
            backgroundColor: AppColors.paid,
            duration:        Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _auth.currentUser?.email == AppConstants.adminEmail;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Prayer Requests',
          style: TextStyle(
            color:      Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Prayer header
            FadeInDown(
              child: Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:        AppColors.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.volunteer_activism,
                      color: Colors.white,
                      size:  40,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Submit a Prayer Request',
                      style: TextStyle(
                        fontSize:   18,
                        fontWeight: FontWeight.bold,
                        color:      Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"The prayer of a righteous person is powerful and effective." — James 5:16',
                      style: TextStyle(
                        fontSize:  13,
                        color:     Colors.white.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit form
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color:        Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color:      Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Prayer Request',
                      style: TextStyle(
                        fontSize:   15,
                        fontWeight: FontWeight.bold,
                        color:      AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        filled:    true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:   BorderSide.none,
                        ),
                      ),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedCategory = val!),
                    ),
                    const SizedBox(height: 12),

                    // Prayer request text
                    TextField(
                      controller: _requestController,
                      maxLines:   5,
                      decoration: InputDecoration(
                        hintText:  'Share your prayer request here...',
                        hintStyle: const TextStyle(
                            color: AppColors.textLight),
                        filled:    true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide:   BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Anonymous toggle
                    Row(
                      children: [
                        Checkbox(
                          value:       _isAnonymous,
                          activeColor: AppColors.primary,
                          onChanged:   (val) =>
                              setState(() => _isAnonymous = val!),
                        ),
                        const Text(
                          'Submit anonymously',
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Submit button
                    SizedBox(
                      width:  double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _submitPrayer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width:  20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color:       Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: const Text(
                          'Submit Prayer Request',
                          style: TextStyle(
                            fontSize:   15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Admin view — all prayer requests
            if (isAdmin) ...[
              const Text(
                'All Prayer Requests',
                style: TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.bold,
                  color:      AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('prayers')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No prayer requests yet.',
                        style: TextStyle(color: AppColors.textGrey),
                      ),
                    );
                  }

                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final prayer = PrayerRequest.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                      return _PrayerCard(
                        prayer:  prayer,
                        isAdmin: isAdmin,
                      );
                    }).toList(),
                  );
                },
              ),
            ] else ...[
              // Member view — their own prayers
              const Text(
                'My Prayer Requests',
                style: TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.bold,
                  color:      AppColors.textDark,
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('prayers')
                    .where('memberEmail', isEqualTo: _memberEmail)
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:        Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'You have not submitted any prayer requests yet.',
                          style: TextStyle(color: AppColors.textGrey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: snapshot.data!.docs.map((doc) {
                      final prayer = PrayerRequest.fromFirestore(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      );
                      return _PrayerCard(
                        prayer:  prayer,
                        isAdmin: isAdmin,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final PrayerRequest prayer;
  final bool          isAdmin;

  const _PrayerCard({
    required this.prayer,
    required this.isAdmin,
  });

  Color get _statusColor {
    switch (prayer.status) {
      case 'Prayed':  return AppColors.paid;
      case 'Pending': return AppColors.pending;
      default:        return AppColors.textGrey;
    }
  }

  Color get _categoryColor {
    switch (prayer.category) {
      case 'Healing':               return AppColors.secondary;
      case 'Financial Breakthrough': return AppColors.paid;
      case 'Family':                return AppColors.primary;
      case 'Thanksgiving':          return const Color(0xFFF39C12);
      default:                      return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:      Colors.black.withOpacity(0.04),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical:   3,
                ),
                decoration: BoxDecoration(
                  color:        _categoryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  prayer.category,
                  style: TextStyle(
                    fontSize:   11,
                    color:      _categoryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical:   3,
                ),
                decoration: BoxDecoration(
                  color:        _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  prayer.status,
                  style: TextStyle(
                    fontSize:   11,
                    color:      _statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (isAdmin)
                GestureDetector(
                  onTap: () async {
                    await FirebaseFirestore.instance
                        .collection('prayers')
                        .doc(prayer.id)
                        .update({'status': 'Prayed'});
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Marked as Prayed!'),
                          backgroundColor: AppColors.paid,
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical:   4,
                    ),
                    decoration: BoxDecoration(
                      color:        AppColors.paid,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🙏 Mark Prayed',
                      style: TextStyle(
                        fontSize: 11,
                        color:    Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            prayer.isAnonymous ? 'Anonymous' : prayer.memberName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize:   14,
              color:      AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            prayer.request,
            style: const TextStyle(
              fontSize: 13,
              color:    AppColors.textGrey,
              height:   1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd MMM yyyy').format(prayer.createdAt),
            style: const TextStyle(
              fontSize: 11,
              color:    AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}