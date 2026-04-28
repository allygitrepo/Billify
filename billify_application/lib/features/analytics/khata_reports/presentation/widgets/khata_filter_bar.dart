import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/features/analytics/khata_reports/providers/khata_reports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class KhataFilterBar extends ConsumerWidget {
  const KhataFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(khataReportsProvider);
    final notifier = ref.read(khataReportsProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _DateChip(
            label: 'Today',
            isSelected: _isSameDay(state.startDate, DateTime.now()),
            onTap: () => notifier.updateFilters(
              start: DateTime.now(),
              end: DateTime.now(),
            ),
          ),
          _DateChip(
            label: 'Last 7 Days',
            isSelected: _isSameDay(
              state.startDate,
              DateTime.now().subtract(const Duration(days: 7)),
            ),
            onTap: () => notifier.updateFilters(
              start: DateTime.now().subtract(const Duration(days: 7)),
              end: DateTime.now(),
            ),
          ),
          _DateChip(
            label: 'This Month',
            isSelected: state.startDate?.month == DateTime.now().month,
            onTap: () {
              final now = DateTime.now();
              notifier.updateFilters(
                start: DateTime(now.year, now.month, 1),
                end: now,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.date_range, color: AppTheme.primaryTeal),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: DateTimeRange(
                  start: state.startDate ?? DateTime.now(),
                  end: state.endDate ?? DateTime.now(),
                ),
              );
              if (range != null) {
                notifier.updateFilters(start: range.start, end: range.end);
              }
            },
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DateChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.primaryTeal.withOpacity(0.12),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected
              ? AppTheme.primaryTeal
              : Theme.of(context).hintColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCheckmark: false,
      ),
    );
  }
}
