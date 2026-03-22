import 'dart:convert';
import 'package:http/http.dart' as http;

class SmsService {
  // ── Africa's Talking credentials ──
  // Replace with your real API key
  static const String _apiKey =
      'atsk_b3ea8e45e742a60220030d20e35a79691374d38e07501be0f63f553e9d14d4b7a50d1e37';
  static const String _username = 'sandbox';
  static const String _senderId = 'ChurchConnect';

  static const String _baseUrl =
      'https://api.sandbox.africastalking.com/version1/messaging';

  // ── Send a single SMS ──
  Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      // Format Ghana phone number
      final formatted = _formatGhanaNumber(phoneNumber);
      print('Sending SMS to: $formatted');
      print('Message: $message');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'apiKey': _apiKey,
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'username': _username,
          'to': formatted,
          'message': message,
          'from': _senderId,
        },
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['SMSMessageData']['Recipients'][0]['status'] ?? '';
        print('SMS status: $status');
        return status == 'Success';
      }
      return false;
    } catch (e) {
      print('SMS error: $e');
      return false;
    }
  }

  // ── Send SMS to multiple recipients ──
  Future<Map<String, bool>> sendBulkSms({
    required List<String> phoneNumbers,
    required String message,
  }) async {
    Map<String, bool> results = {};
    for (final number in phoneNumbers) {
      final success = await sendSms(
        phoneNumber: number,
        message: message,
      );
      results[number] = success;
      // Small delay between messages
      await Future.delayed(const Duration(milliseconds: 500));
    }
    return results;
  }

  // ── Pre-built message templates ──

  // Payment receipt message
  String paymentReceiptMessage({
    required String memberName,
    required double amount,
    required String paymentType,
  }) {
    return 'Dear $memberName, your payment of GHS ${amount.toStringAsFixed(2)} '
        'for $paymentType has been received. '
        'God bless you for your faithfulness. '
        '- ChurchConnect';
  }

  // Overdue dues reminder message
  String overdueReminderMessage({
    required String memberName,
    required double amountOutstanding,
  }) {
    return 'Dear $memberName, this is a friendly reminder that '
        'your church dues of GHS ${amountOutstanding.toStringAsFixed(2)} '
        'are outstanding. Kindly settle at your earliest convenience. '
        'God bless you. - ChurchConnect';
  }

  // Event announcement message
  String eventAnnouncementMessage({
    required String memberName,
    required String eventTitle,
    required String eventDate,
    required String location,
  }) {
    return 'Dear $memberName, you are invited to $eventTitle '
        'on $eventDate at $location. '
        'We look forward to seeing you! '
        '- ChurchConnect';
  }

  // Welcome new member message
  String welcomeMessage({
    required String memberName,
  }) {
    return 'Dear $memberName, welcome to our church family! '
        'We are glad to have you with us. '
        'God bless you abundantly. '
        '- ChurchConnect';
  }

  // ── Format Ghana phone number ──
  String _formatGhanaNumber(String phone) {
    // Remove all spaces and dashes
    phone = phone.replaceAll(RegExp(r'[\s\-]'), '');

    // Already has country code
    if (phone.startsWith('+233')) return phone;
    if (phone.startsWith('233')) return '+$phone';

    // Local format starting with 0
    if (phone.startsWith('0')) {
      return '+233${phone.substring(1)}';
    }

    return '+233$phone';
  }
}
