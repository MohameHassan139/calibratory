import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static const _url = 'https://api.emailjs.com/api/v1.0/email/send';
  static const _serviceId = 'service_64t2ewn';
  static const _userId = 'AZHS7uGhXsLQ0J5WK';
  static const _priceOfferTemplateId = 'template_i8gmiim';
  static const _certificateTemplateId = 'template_6s0lw38';

  static Future<bool> sendPriceOfferEmail({
    required String toEmail,
    required String clientName,
    required String engineerName,
    required double total,
    required List<Map<String, dynamic>> items,
  }) async {
    final rows = StringBuffer();
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final fp = (item['functionPrice'] as num).toStringAsFixed(0);
      final sp = (item['safetyPrice'] as num).toStringAsFixed(0);
      final sub = (item['subtotal'] as num).toStringAsFixed(0);
      final bg = i % 2 == 0 ? '#ffffff' : '#f8fafc';

      final funcChecked = item['functionCheck'] == true;
      final safeChecked = item['safetyCheck'] == true;

      final funcText = funcChecked ? '&#10004; \$$fp' : '&mdash;';
      final safeText = safeChecked ? '&#10004; \$$sp' : '&mdash;';
      final funcColor = funcChecked ? '#1565C0' : '#90A4AE';
      final safeColor = safeChecked ? '#00897B' : '#90A4AE';
      final funcWeight = funcChecked ? '700' : '400';
      final safeWeight = safeChecked ? '700' : '400';

      rows.write('<tr style="background:$bg;">');
      rows.write(
          '<td style="padding:11px 16px;color:#0D1B2A;font-size:13px;border-bottom:1px solid #EEF2F8;">${item['name']}</td>');
      rows.write(
          '<td style="padding:11px 16px;font-size:13px;border-bottom:1px solid #EEF2F8;text-align:center;color:$funcColor;font-weight:$funcWeight;">$funcText</td>');
      rows.write(
          '<td style="padding:11px 16px;font-size:13px;border-bottom:1px solid #EEF2F8;text-align:center;color:$safeColor;font-weight:$safeWeight;">$safeText</td>');
      rows.write(
          '<td style="padding:11px 16px;color:#546E7A;font-size:13px;border-bottom:1px solid #EEF2F8;text-align:center;font-weight:600;">${item['qty']}</td>');
      rows.write(
          '<td style="padding:11px 16px;color:#1565C0;font-size:13px;border-bottom:1px solid #EEF2F8;text-align:right;font-weight:700;">\$$sub</td>');
      rows.write('</tr>');
    }

    final payload = {
      'service_id': _serviceId,
      'template_id': _priceOfferTemplateId,
      'user_id': _userId,
      'template_params': {
        'to_email': toEmail,
        'client_name': clientName,
        'engineer_name': engineerName,
        'total': '\$${total.toStringAsFixed(0)}',
        'items_rows': rows.toString(),
        'offer_date': _formatDate(DateTime.now()),
      },
    };

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      print('📧 EmailJS status: ${response.statusCode}');
      print('📧 EmailJS body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('📧 EmailJS exception: $e');
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
      'service_id': _serviceId,
      'template_id': _certificateTemplateId,
      'user_id': _userId,
      'template_params': {
        'to_email': toEmail,
        'client_name': clientName,
        'engineer_name': engineerName,
        'serial_number': serialNumber,
        'model': model,
        'result': passed ? 'PASS ✅' : 'FAIL ❌',
        'certificate_url': certificateUrl,
        'calibration_date': _formatDate(DateTime.now()),
      },
    };

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );
      print('📧 Certificate email status: ${response.statusCode}');
      print('📧 Certificate email body: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('📧 Certificate email exception: $e');
      return false;
    }
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}
