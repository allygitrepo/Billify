import 'package:billify_application/core/theme/app_theme.dart';
import 'package:billify_application/data/models/uom_model.dart';
import 'package:billify_application/presentation/widgets/custom_text_field.dart';
import 'package:billify_application/providers/uom_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

class UomManagementPage extends ConsumerWidget {
  const UomManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uoms = ref.watch(uomProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unit of Measure Management'),
      ),
      body: uoms.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.straighten, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No UOMs added yet', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: uoms.length,
              itemBuilder: (context, index) {
                final uom = uoms[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(uom.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => _showAddEditBottomSheet(context, ref, uom),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          onPressed: () => _showDeleteDialog(context, ref, uom),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditBottomSheet(context, ref),
        backgroundColor: AppTheme.primaryTeal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddEditBottomSheet(BuildContext context, WidgetRef ref, [UomModel? uom]) {
    final controller = TextEditingController(text: uom?.name);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  uom == null ? 'Add Unit' : 'Edit Unit',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  controller: controller,
                  label: 'UOM Name',
                  hint: 'e.g. KG',
                  autofocus: true,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CANCEL'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (controller.text.isNotEmpty) {
                            final newUom = UomModel(
                              id: uom?.id ?? const Uuid().v4(),
                              name: controller.text.trim(),
                            );
                            ref.read(uomProvider.notifier).saveUom(newUom);
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(uom == null ? 'ADD' : 'SAVE'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, UomModel uom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete UOM'),
        content: Text('Are you sure you want to delete "${uom.name}"? Products using this UOM will default back to Pcs.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              ref.read(uomProvider.notifier).deleteUom(uom.id);
              Navigator.pop(context);
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
