class AppConstants {
  // ── Church Details ──
  static const String churchName        = 'Great Mountains Of God International Ministry';
  static const String churchShortName   = 'GMOGIM';
  static const String churchMotto       = 'Great ooo... Anointing ooo...';
  static const String churchLocation    = 'Kasoa, Galilea - Cola Factory';
  static const String churchPhone1      = '+233 24 762 0088';
  static const String churchPhone2      = '+233 26 262 0088';
  static const String churchEmail       = 'greatmountainsofgod@gmail.com';
  static const String pastorName        = 'Apostle Wisdom Wetsi';
  static const String adminEmail        = 'greatmountainsofgod@gmail.com';

  // ── Firestore Collections ──
  static const String membersCollection  = 'members';
  static const String paymentsCollection = 'payments';
  static const String eventsCollection   = 'events';

  // ── Departments ──
  static const List<String> departments = [
    'General',
    'Youth',
    'Instrumentalist',
    'Singers',
    'Ushers',
    'Children Ministry',
    'Prayer Warriors',
    'Pastors',
  ];

  // ── Payment Types ──
  static const List<String> paymentTypes = [
    'Monthly Dues',
    'Tithe',
    'Offering',
    'Building Fund',
    'Welfare',
    'Other',
  ];

  // ── Dues Status ──
  static const String statusPaid    = 'Paid';
  static const String statusPending = 'Pending';
  static const String statusOverdue = 'Overdue';
}