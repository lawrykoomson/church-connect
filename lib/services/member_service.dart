import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member_model.dart';
import '../utils/app_constants.dart';

class MemberService {
  final _firestore = FirebaseFirestore.instance;

  // Get all members as a stream
  Stream<List<Member>> getMembers() {
    return _firestore
        .collection(AppConstants.membersCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Member.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Add a new member
  Future<void> addMember(Member member) async {
    await _firestore
        .collection(AppConstants.membersCollection)
        .add(member.toFirestore());
  }

  // Update an existing member
  Future<void> updateMember(Member member) async {
    await _firestore
        .collection(AppConstants.membersCollection)
        .doc(member.id)
        .update(member.toFirestore());
  }

  // Delete a member
  Future<void> deleteMember(String memberId) async {
    await _firestore
        .collection(AppConstants.membersCollection)
        .doc(memberId)
        .delete();
  }

  // Search members by name
  Future<List<Member>> searchMembers(String query) async {
    final snap =
        await _firestore.collection(AppConstants.membersCollection).get();
    return snap.docs
        .map((doc) => Member.fromFirestore(doc.data(), doc.id))
        .where((m) =>
            m.fullName.toLowerCase().contains(query.toLowerCase()) ||
            m.phoneNumber.contains(query) ||
            m.email.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}
