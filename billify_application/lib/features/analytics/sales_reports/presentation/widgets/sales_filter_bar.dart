import 'package:billify/core/theme/app_theme.dart';
import 'package:billify/features/analytics/sales_reports/providers/sales_reports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SalesFilterBar extends ConsumerWidget {
  const SalesFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salesReportsProvider);
    final notifier = ref.read(salesReportsProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _QuickFilterChip(
            label: 'Today',
            isSelected:
                _isSameDay(state.startDate, DateTime.now()) &&
                _isSameDay(state.endDate, DateTime.now()),
            onTap: () => notifier.updateFilters(
              start: DateTime.now(),
              end: DateTime.now(),
            ),
          ),
          _QuickFilterChip(
            label: 'Yesterday',
            isSelected: _isSameDay(
              state.startDate,
              DateTime.now().subtract(const Duration(days: 1)),
            ),
            onTap: () {
              final yesterday = DateTime.now().subtract(
                const Duration(days: 1),
              );
              notifier.updateFilters(start: yesterday, end: yesterday);
            },
          ),
          _QuickFilterChip(
            label: 'This Week',
            isSelected: _isThisWeek(state.startDate),
            onTap: () {
              final now = DateTime.now();
              final start = now.subtract(Duration(days: now.weekday - 1));
              notifier.updateFilters(start: start, end: now);
            },
          ),
          _QuickFilterChip(
            label: 'This Month',
            isSelected:
                state.startDate?.month == DateTime.now().month &&
                state.startDate?.year == DateTime.now().year,
            onTap: () {
              final now = DateTime.now();
              final start = DateTime(now.year, now.month, 1);
              notifier.updateFilters(start: start, end: now);
            },
          ),
          IconButton(
            icon: const Icon(Icons.date_range, color: AppTheme.primaryTeal),
            onPressed: () async {
              final range = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
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

  bool _isThisWeek(DateTime? date) {
    if (date == null) return false;
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    return date.isAfter(start.subtract(const Duration(seconds: 1)));
  }
}

class _QuickFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _QuickFilterChip({
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
        selectedColor: AppTheme.primaryTeal.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected
              ? AppTheme.primaryTeal
              : Theme.of(context).hintColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        showCheckmark: false,
      ),
    );
  }
}
