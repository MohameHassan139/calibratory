// lib/presentation/services/email_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  /// Calls the Firebase Cloud Function to send certificate email.
  /// The Cloud Function handles SMTP via nodemailer.
  static Future<bool> sendCertificateEmail({
    required String toEmail,
    required String clientName,
    required String engineerName,
    required String serialNumber,
    required String model,
    required bool passed,
    required String certificateUrl,
  }) async {
    try {
      // Replace with your deployed Firebase Cloud Function URL
      const functionUrl =
          'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/sendCertificateEmail';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'toEmail': toEmail,
          'clientName': clientName,
          'engineerName': engineerName,
          'serialNumber': serialNumber,
          'model': model,
          'passed': passed,
          'certificateUrl': certificateUrl,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Sends a price offer email to the client.
  static Future<bool> sendPriceOfferEmail({
    required String toEmail,
    required String clientName,
    required String engineerName,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      const functionUrl =
          'https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/sendPriceOfferEmail';

      final response = await http.post(
        Uri.parse(functionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'toEmail': toEmail,
          'clientName': clientName,
          'engineerName': engineerName,
          'total': total,
          'items': items,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
