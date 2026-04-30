import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/calibration_controller.dart';
import 'calibration_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _filter = 'All'; // All | PASS | FAIL

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<CalibrationController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Calibration History'),
        automaticallyImplyLeading: false,
        actions: [
          Obx(() => ctrl.isLoading.value
              ? const Padding(
                  padding: EdgeInsets.all(14),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: ctrl.loadHistory,
                )),
        ],
      ),
      body: Column(
        children: [
          // ── Search + Filter bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search by hospital, model, serial…',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textHint),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppColors.textHint),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                ),
                const SizedBox(height: 10),
                // Filter chips
                Row(
                  children: ['All', 'PASS', 'FAIL'].map((f) {
                    final selected = _filter == f;
                    Color chipColor = AppColors.accent;
                    if (f == 'PASS') chipColor = AppColors.success;
                    if (f == 'FAIL') chipColor = AppColors.error;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected ? chipColor : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? chipColor : AppColors.border,
                            ),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // ── List ────────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (ctrl.isLoading.value && ctrl.history.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final filtered = ctrl.history.where((s) {
                final matchesFilter =
                    _filter == 'All' || s.overallResult == _filter;
                final matchesQuery = _query.isEmpty ||
                    s.customerName.toLowerCase().contains(_query) ||
                    s.serialNumber.toLowerCase().contains(_query) ||
                    s.model.toLowerCase().contains(_query) ||
                    s.manufacturer.toLowerCase().contains(_query) ||
                    s.department.toLowerCase().contains(_query);
                return matchesFilter && matchesQuery;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _query.isNotEmpty || _filter != 'All'
                            ? Icons.search_off_rounded
                            : Icons.history_edu_outlined,
                        size: 64,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _query.isNotEmpty || _filter != 'All'
                            ? 'No results found'
                            : 'No calibration sessions yet',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 15),
                      ),
                      if (_query.isNotEmpty || _filter != 'All') ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _query = '';
                              _filter = 'All';
                            });
                          },
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) => _HistoryCard(
                  session: filtered[i],
                  onTap: () => Get.to(
                    () => CalibrationDetailScreen(session: filtered[i]),
                    transition: Transition.rightToLeft,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── History Card ──────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  final dynamic session;
  final VoidCallback onTap;
  const _HistoryCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final result = session.overallResult as String?;
    final Color resultColor = result == 'PASS'
        ? AppColors.success
        : result == 'FAIL'
            ? AppColors.error
            : AppColors.textHint;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Result indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: resultColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                result == 'PASS'
                    ? Icons.check_circle_outline
                    : result == 'FAIL'
                        ? Icons.cancel_outlined
                        : Icons.pending_outlined,
                color: resultColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.customerName.isEmpty
                        ? 'Unknown Hospital'
                        : session.customerName,
                    style: const TextStyle(
                      fontFamily: 'Syne',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${session.manufacturer} · ${session.model}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'S/N: ${session.serialNumber}  ·  ${session.department}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textHint),
                  ),
                ],
              ),
            ),
            // Date + chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${session.visitDate.day}/${session.visitDate.month}/${session.visitDate.year}',
                  style:
                      const TextStyle(fontSize: 11, color: AppColors.textHint),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    result ?? 'N/F',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: resultColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
