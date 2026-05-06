import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

class WhatsappService {
  static Future<void> shareFile({
    required File file,
    required String text,
    String? phone,
  }) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: text,
    );
  }
  static Future<void> sendInvoice({
    required String phone,
    required String invoiceId,
    required double amount,
    File? pdfFile,
  }) async {
    // Format phone number (ensure it has country code, default to +91 for India if not present)
    String formattedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (formattedPhone.length == 10) {
      formattedPhone = '91$formattedPhone';
    }

    String message = 
        'Hello! Here is your invoice from Billify.\n\n'
        'Invoice No: $invoiceId\n'
        'Amount: ₹${amount.toStringAsFixed(2)}\n\n'
        'Thank you for shopping with us!';

    if (pdfFile != null) {
      await shareFile(
        file: pdfFile,
        text: message,
        phone: formattedPhone,
      );
      return;
    }

    final Uri whatsappUrl = Uri.parse(
      'whatsapp://send?phone=$formattedPhone&text=${Uri.encodeComponent(message)}',
    );

    try {
      // 1. Try launching the WhatsApp App directly (whatsapp://)
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        return;
      }

      // 2. Fallback to Web link (https://wa.me/)
      // We don't check canLaunchUrl here as it's a standard web link
      final Uri webUrl = Uri.parse(
        'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}',
      );
      
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      
    } catch (e) {
      print('Error launching WhatsApp: $e');
      // If everything fails, show a snackbar or throw
      rethrow;
    }
  }

  static Future<void> sendBalanceReminder({
    required String phone,
    required double balance,
    required String businessName,
    File? pdfFile,
  }) async {
    String formattedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (formattedPhone.length == 10) {
      formattedPhone = '91$formattedPhone';
    }

    String message = '';
    if (balance > 0) {
      message = 
          'Hello! This is a friendly reminder from $businessName regarding your outstanding balance.\n\n'
          'Pending Amount: ₹${balance.toStringAsFixed(2)}\n\n'
          'Please clear your dues at your earliest convenience. Thank you!';
    } else {
      message = 
          'Hello! Regarding our accounts at $businessName:\n\n'
          'Current Balance: ₹${balance.abs().toStringAsFixed(2)} (Advance/Credit)\n\n'
          'Thank you for your business!';
    }

    if (pdfFile != null) {
      await shareFile(
        file: pdfFile,
        text: message,
        phone: formattedPhone,
      );
      return;
    }

    final Uri whatsappUrl = Uri.parse(
      'whatsapp://send?phone=$formattedPhone&text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
        return;
      }
      final Uri webUrl = Uri.parse(
        'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(message)}',
      );
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      print('Error launching WhatsApp: $e');
      rethrow;
    }
  }
}
