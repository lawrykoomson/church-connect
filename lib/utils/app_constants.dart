class AppConstants {
  static const String appName = 'ChurchConnect';
  static const String appTagline = 'Church Management System';
  static const String adminPortal = 'Admin Portal Only';

  static const String membersCollection = 'members';
  static const String paymentsCollection = 'payments';
  static const String eventsCollection = 'events';

  static const List<String> departments = [
    'General',
    'Choir',
    'Youth',
    "Women's Fellowship",
    "Men's Fellowship",
    'Ushers',
    'Children Ministry',
    'Prayer Team',
  ];

  static const List<String> paymentTypes = [
    'Monthly Dues',
    'Tithe',
    'Building Fund',
    'Special Offering',
    'Harvest',
    'Other',
  ];

  static const String statusPaid = 'Paid';
  static const String statusPending = 'Pending';
  static const String statusOverdue = 'Overdue';
}
