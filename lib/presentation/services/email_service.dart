import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const _baseUrl = 'https://node-learn-theta.vercel.app/api/email';

  // ── Price Offer ──────────────────────────────────────────────────────────────
  static Future<bool> sendPriceOfferEmail({
    required String toEmail,
    required String clientName,
    required String engineerName,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    final payload = {
      'toEmail': toEmail,
      'clientName': clientName,
      'engineerName': engineerName,
      'total': total,
      'items': items,
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/price-offer'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      print('📧 Price offer status: ${response.statusCode}');
      print('📧 Price offer body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('📧 Price offer exception: $e');
      return false;
    }
  }


static Future<bool> sendCertificateEmail({
    required String toEmail,
    required String clientName,
    required String engineerName,
    required String serialNumber,
    required String model,
    required bool passed,
    required String certificateUrl,
  }) async {
    final payload = {
      'toEmail': toEmail.trim(),
      'clientName': clientName.trim(),
      'engineerName': engineerName.trim(),
      'serialNumber': serialNumber.trim(),
      'model': model.trim(),
      'passed': passed,
      'certificateUrl': certificateUrl.trim(),
    };

    final bodyStr = json.encode(payload);
    print('📧 Certificate email payload: $bodyStr');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/certificate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: bodyStr,
      );
      print('📧 Certificate email status: ${response.statusCode}');
      print('📧 Certificate email body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('📧 Certificate email exception: $e');
      return false;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
