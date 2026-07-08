import 'package:url_launcher/url_launcher.dart';

class SharingHelper {
  static String cleanPhone(String? phoneNum) {
    if (phoneNum == null) return "";
    var cleaned = phoneNum.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length == 10) cleaned = "91" + cleaned;
    return cleaned;
  }

  static Future<bool> sendWhatsApp({
    required String? phone,
    required String message,
  }) async {
    final cleaned = cleanPhone(phone);
    if (cleaned.isEmpty) return false;

    final whatsappUrl = Uri.parse("whatsapp://send?phone=$cleaned&text=${Uri.encodeComponent(message)}");
    final webUrl = Uri.parse("https://wa.me/$cleaned?text=${Uri.encodeComponent(message)}");

    if (await canLaunchUrl(whatsappUrl)) {
      return await launchUrl(whatsappUrl);
    } else if (await canLaunchUrl(webUrl)) {
      return await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> sendSMS({
    required String? phone,
    required String message,
  }) async {
    final cleaned = cleanPhone(phone);
    if (cleaned.isEmpty) return false;

    // Use default SMS scheme syntax
    final uri = Uri.parse("sms:$cleaned?body=${Uri.encodeComponent(message)}");
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }
}
