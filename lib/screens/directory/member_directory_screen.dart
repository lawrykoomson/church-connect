import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:animate_do/animate_do.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';

class MemberDirectoryScreen extends StatefulWidget {
  const MemberDirectoryScreen({super.key});

  @override
  State<MemberDirectoryScreen> createState() =>
      _MemberDirectoryScreenState();
}

class _MemberDirectoryScreenState
    extends State<MemberDirectoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery     = '';
  String _selectedDept    = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Member Directory',
          style: TextStyle(
            color:      Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [

          // Search and filter bar
          Container(
            color:   AppColors.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:  'Search members...',
                    hintStyle: const TextStyle(color: Colors.white60),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Colors.white60,
                    ),
                    filled:    true,
                    fillColor: Colors.white.withOpacity(0.15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:   BorderSide.none,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: Colors.white60,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) =>
                      setState(() => _searchQuery = val.toLowerCase()),
                ),
                const SizedBox(height: 10),

                // Department filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'All',
                      ...AppConstants.departments,
                    ].map((dept) {
                      final isSelected = _selectedDept == dept;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedDept = dept),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical:   6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            dept,
                            style: TextStyle(
                              fontSize:   12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Members list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(AppConstants.membersCollection)
                  .orderBy('fullName')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  );
                }

                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No members found.',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  );
                }

                var members = snapshot.data!.docs.where((doc) {
                  final data     = doc.data() as Map<String, dynamic>;
                  final name     = (data['fullName'] ?? '').toLowerCase();
                  final dept     = data['department'] ?? '';
                  final matchSearch = _searchQuery.isEmpty ||
                      name.contains(_searchQuery);
                  final matchDept = _selectedDept == 'All' ||
                      dept == _selectedDept;
                  return matchSearch && matchDept;
                }).toList();

                if (members.isEmpty) {
                  return const Center(
                    child: Text(
                      'No members match your search.',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  );
                }

                return ListView.builder(
                  padding:     const EdgeInsets.all(16),
                  itemCount:   members.length,
                  itemBuilder: (context, index) {
                    final data = members[index].data()
                        as Map<String, dynamic>;
                    return FadeInUp(
                      delay: Duration(milliseconds: index * 50),
                      child: _MemberCard(data: data),
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

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _MemberCard({required this.data});

  Color get _deptColor {
    switch (data['department']) {
      case 'Youth':             return const Color(0xFF8E44AD);
      case 'Singers':           return AppColors.secondary;
      case 'Instrumentalist':   return const Color(0xFF2980B9);
      case 'Ushers':            return AppColors.paid;
      case 'Prayer Warriors':   return AppColors.primary;
      case 'Pastors':           return const Color(0xFFF39C12);
      case 'Children Ministry': return const Color(0xFF16A085);
      default:                  return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name   = data['fullName']    ?? '';
    final dept   = data['department']  ?? 'General';
    final status = data['duesStatus']  ?? 'Pending';
    final phone  = data['phoneNumber'] ?? '';

    return Container(
      margin:  const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          // Avatar
          Container(
            width:  48,
            height: 48,
            decoration: BoxDecoration(
              color:  _deptColor.withOpacity(0.15),
              shape:  BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty
                    ? name.substring(0, 1).toUpperCase()
                    : 'M',
                style: TextStyle(
                  fontSize:   20,
                  fontWeight: FontWeight.bold,
                  color:      _deptColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize:   15,
                    color:      AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical:   2,
                      ),
                      decoration: BoxDecoration(
                        color:        _deptColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        dept,
                        style: TextStyle(
                          fontSize:   11,
                          color:      _deptColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color:    AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dues status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical:   4,
            ),
            decoration: BoxDecoration(
              color: status == 'Paid'
                  ? AppColors.paid.withOpacity(0.1)
                  : status == 'Overdue'
                      ? AppColors.overdue.withOpacity(0.1)
                      : AppColors.pending.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize:   11,
                fontWeight: FontWeight.bold,
                color: status == 'Paid'
                    ? AppColors.paid
                    : status == 'Overdue'
                        ? AppColors.overdue
                        : AppColors.pending,
              ),
            ),
          ),
        ],
      ),
    );
  }
}