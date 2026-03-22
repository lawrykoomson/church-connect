import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/app_colors.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'add_event_screen.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final eventService = EventService();
    final currentUser = FirebaseAuth.instance.currentUser;
    final isAdmin = currentUser?.email == 'churchconnect71@gmail.com';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Event Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<Event>>(
        stream: eventService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.secondary,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 64,
                    color: AppColors.textLight,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No events yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textGrey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAdmin
                        ? 'Tap + to create your first event'
                        : 'Check back later for upcoming events',
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                ],
              ),
            );
          }

          final events = snapshot.data!;
          final upcoming =
              events.where((e) => e.date.isAfter(DateTime.now())).toList();
          final past =
              events.where((e) => e.date.isBefore(DateTime.now())).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Upcoming Events ──
              if (upcoming.isNotEmpty) ...[
                const Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 12),
                ...upcoming.map((event) => _EventCard(
                      event: event,
                      isPast: false,
                      isAdmin: isAdmin,
                      onDelete: () => eventService.deleteEvent(event.id),
                    )),
                const SizedBox(height: 24),
              ],

              // ── Past Events ──
              if (past.isNotEmpty) ...[
                const Text(
                  'Past Events',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textGrey,
                  ),
                ),
                const SizedBox(height: 12),
                ...past.map((event) => _EventCard(
                      event: event,
                      isPast: true,
                      isAdmin: isAdmin,
                      onDelete: () => eventService.deleteEvent(event.id),
                    )),
              ],
            ],
          );
        },
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AddEventScreen(),
                ),
              ),
              backgroundColor: AppColors.secondary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Add Event',
                style: TextStyle(color: Colors.white),
              ),
            )
          : null,
    );
  }
}

// ══════════════════════════════════════════════
// EVENT CARD WIDGET
// ══════════════════════════════════════════════
class _EventCard extends StatelessWidget {
  final Event event;
  final bool isPast;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _EventCard({
    required this.event,
    required this.isPast,
    required this.isAdmin,
    required this.onDelete,
  });

  Color get _categoryColor {
    switch (event.category) {
      case 'Worship':
        return AppColors.primary;
      case 'Youth':
        return AppColors.secondary;
      case 'Women':
        return const Color(0xFF8E44AD);
      case 'Men':
        return const Color(0xFF2980B9);
      case 'Harvest':
        return AppColors.paid;
      default:
        return AppColors.textGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isPast ? Colors.white.withOpacity(0.6) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top colour bar
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: isPast ? AppColors.textLight : _categoryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date box
                Container(
                  width: 50,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isPast
                        ? AppColors.background
                        : _categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('dd').format(event.date),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isPast ? AppColors.textGrey : _categoryColor,
                        ),
                      ),
                      Text(
                        DateFormat('MMM').format(event.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: isPast ? AppColors.textLight : _categoryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Event info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isPast
                                    ? AppColors.textGrey
                                    : AppColors.textDark,
                              ),
                            ),
                          ),
                          // Delete button — admin only
                          if (isAdmin)
                            GestureDetector(
                              onTap: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete Event'),
                                    content: Text('Delete "${event.title}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(
                                            color: AppColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) onDelete();
                              },
                              child: const Icon(
                                Icons.delete_outline,
                                color: AppColors.textLight,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textGrey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          // Category chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isPast
                                  ? AppColors.background
                                  : _categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              event.category,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isPast
                                    ? AppColors.textLight
                                    : _categoryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (event.location.isNotEmpty) ...[
                            const Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                event.location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textLight,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('h:mm a').format(event.date),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
