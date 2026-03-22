import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';
import '../utils/app_constants.dart';

class EventService {
  final _firestore = FirebaseFirestore.instance;

  // Get all events as stream
  Stream<List<Event>> getEvents() {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Event.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Add a new event
  Future<void> addEvent(Event event) async {
    await _firestore
        .collection(AppConstants.eventsCollection)
        .add(event.toFirestore());
  }

  // Update an event
  Future<void> updateEvent(Event event) async {
    await _firestore
        .collection(AppConstants.eventsCollection)
        .doc(event.id)
        .update(event.toFirestore());
  }

  // Delete an event
  Future<void> deleteEvent(String eventId) async {
    await _firestore
        .collection(AppConstants.eventsCollection)
        .doc(eventId)
        .delete();
  }

  // Get upcoming events only
  Stream<List<Event>> getUpcomingEvents() {
    return _firestore
        .collection(AppConstants.eventsCollection)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Event.fromFirestore(doc.data(), doc.id))
            .where((e) => e.date.isAfter(DateTime.now()))
            .toList());
  }
}
