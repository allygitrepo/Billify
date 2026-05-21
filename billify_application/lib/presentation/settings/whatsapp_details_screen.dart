import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/core/utils/image_utils.dart';
import 'package:billify/providers/whatsapp_provider.dart';
import 'package:billify/presentation/widgets/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WhatsappDetailsScreen extends ConsumerWidget {
  const WhatsappDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final whatsappState = ref.watch(whatsappProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'WhatsApp Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: whatsappState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryTeal),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  // Profile Section Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // WhatsApp Icon & Avatar
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFF25D366),
                                  width: 3,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: isDark ? Colors.grey[900] : Colors.grey[200],
                                backgroundImage: whatsappState.profileImage != null &&
                                        whatsappState.profileImage!.isNotEmpty
                                    ? (whatsappState.profileImage!.startsWith('http')
                                        ? NetworkImage(whatsappState.profileImage!)
                                        : MemoryImage(
                                            ImageUtils.decodeBase64(whatsappState.profileImage!),
                                          ) as ImageProvider)
                                    : null,
                                child: whatsappState.profileImage == null ||
                                        whatsappState.profileImage!.isEmpty
                                    ? Icon(
                                        Icons.person,
                                        size: 55,
                                        color: Colors.grey[400],
                                      )
                                    : null,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFF25D366),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                'assets/whatsapp-icon.webp',
                                width: 18,
                                height: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Status Indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 4,
                                backgroundColor: Color(0xFF25D366),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Active & Linked',
                                style: TextStyle(
                                  color: Color(0xFF25D366),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),
                        // Detail Fields
                        _buildDetailTile(
                          context,
                          label: 'Pushname (Account Name)',
                          value: whatsappState.name ?? 'Not Available',
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 16),
                        _buildDetailTile(
                          context,
                          label: 'WhatsApp Number',
                          value: whatsappState.phone != null
                              ? '+${whatsappState.phone}'
                              : 'Not Available',
                          icon: Icons.phone_android_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Log Out Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: () => _confirmDisconnect(context, ref),
                      icon: const Icon(Icons.logout_rounded, color: Colors.white),
                      label: const Text(
                        'Disconnect Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryTeal, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDisconnect(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect WhatsApp?'),
        content: const Text(
          'Are you sure you want to disconnect WhatsApp integration? '
          'You will no longer be able to send automatic invoices or reminders via WhatsApp.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DISCONNECT'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(whatsappProvider.notifier).disconnect();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp disconnected successfully')),
          );
          Navigator.pop(context); // Close details page
        }
      } catch (e) {
        if (context.mounted) {
          ErrorHandler.showErrorSnackBar(context, e);
        }
      }
    }
  }
}
