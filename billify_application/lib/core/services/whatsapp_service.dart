import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:billify/core/services/api_service.dart';
import 'package:billify/providers/business_provider.dart';

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
    required WidgetRef ref,
    File? pdfFile,
  }) async {
    // Format phone number (ensure it has country code, default to 91 for India if not present)
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
      final businessId = ref.read(businessProvider).currentBusinessId;
      if (businessId != null) {
        try {
          final bytes = await pdfFile.readAsBytes();
          final base64Pdf = base64Encode(bytes);
          final apiService = ref.read(apiServiceProvider);

          final response = await apiService.post(
            '/businesses/$businessId/whatsapp/send-media',
            data: {
              'number': formattedPhone,
              'pdfBase64': base64Pdf,
              'fileName': 'invoice_$invoiceId.pdf',
              'message': message,
            },
          );

          if (response.statusCode == 200 && response.data['success'] == true) {
            // Sent successfully via WA-Mitra API!
            return;
          }
          
          // If response is not success, throw the server's error message
          final serverError = response.data['message'] ?? 'Failed to send WhatsApp message via server';
          throw Exception(serverError);
        } catch (e) {
          // If API call fails, fallback to local URL launcher/share sheet so the app still functions
          print('[WhatsappService] API send failed, falling back to local sharing: $e');
        }
      }

      // Fallback local share
      await shareFile(
        file: pdfFile,
        text: message,
        phone: formattedPhone,
      );
      return;
    }

    // No PDF file: launch WhatsApp via URL scheme
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

  static Future<void> sendBalanceReminder({
    required String phone,
    required double balance,
    required String businessName,
    required WidgetRef ref,
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
      final businessId = ref.read(businessProvider).currentBusinessId;
      if (businessId != null) {
        try {
          final bytes = await pdfFile.readAsBytes();
          final base64Pdf = base64Encode(bytes);
          final apiService = ref.read(apiServiceProvider);

          final response = await apiService.post(
            '/businesses/$businessId/whatsapp/send-media',
            data: {
              'number': formattedPhone,
              'pdfBase64': base64Pdf,
              'fileName': 'ledger_${businessName.replaceAll(' ', '_')}.pdf',
              'message': message,
            },
          );

          if (response.statusCode == 200 && response.data['success'] == true) {
            // Sent successfully via WA-Mitra API!
            return;
          }

          final serverError = response.data['message'] ?? 'Failed to send WhatsApp message via server';
          throw Exception(serverError);
        } catch (e) {
          print('[WhatsappService] API send failed, falling back to local sharing: $e');
        }
      }

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

  static Future<void> sendBulkReminders({
    required List<Map<String, String>> messages,
    required WidgetRef ref,
  }) async {
    final businessId = ref.read(businessProvider).currentBusinessId;
    if (businessId == null) {
      throw Exception('No active business found');
    }

    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.post(
      '/businesses/$businessId/whatsapp/send-bulk',
      data: {
        'messages': messages,
      },
    );

    if (response.statusCode != 200 || response.data['success'] != true) {
      final errMsg = response.data['message'] ?? 'Failed to send bulk WhatsApp messages';
      throw Exception(errMsg);
    }
  }
}
