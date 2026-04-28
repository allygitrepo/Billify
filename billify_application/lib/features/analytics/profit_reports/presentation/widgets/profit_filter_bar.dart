import 'package:billify/features/analytics/profit_reports/providers/profit_reports_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class ProfitFilterBar extends ConsumerWidget {
  const ProfitFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profitReportsProvider);
    final notifier = ref.read(profitReportsProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _FilterChip(
              label: 'Today',
              isSelected:
                  _isSameDay(state.startDate, DateTime.now()) &&
                  _isSameDay(state.endDate, DateTime.now()),
              onTap: () => notifier.updateFilters(
                start: DateTime.now(),
                end: DateTime.now(),
              ),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Last 7 Days',
              isSelected:
                  state.startDate?.isBefore(
                    DateTime.now().subtract(const Duration(days: 6)),
                  ) ??
                  false,
              onTap: () => notifier.updateFilters(
                start: DateTime.now().subtract(const Duration(days: 6)),
                end: DateTime.now(),
              ),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'This Month',
              isSelected:
                  state.startDate?.month == DateTime.now().month &&
                  state.startDate?.year == DateTime.now().year,
              onTap: () => notifier.updateFilters(
                start: DateTime(DateTime.now().year, DateTime.now().month, 1),
                end: DateTime.now(),
              ),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Custom',
              isSelected: false,
              onTap: () async {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: DateTimeRange(
                    start:
                        state.startDate ??
                        DateTime.now().subtract(const Duration(days: 7)),
                    end: state.endDate ?? DateTime.now(),
                  ),
                );
                if (range != null) {
                  notifier.updateFilters(start: range.start, end: range.end);
                }
              },
            ),
            if (state.startDate != null && state.endDate != null) ...[
              const SizedBox(width: 12),
              Text(
                "${DateFormat('dd MMM').format(state.startDate!)} - ${DateFormat('dd MMM').format(state.endDate!)}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryColor : theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.primaryColor : theme.dividerColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? Colors.white
                : theme.textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
