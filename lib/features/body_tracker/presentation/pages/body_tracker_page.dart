import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/body_tracker_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import '../widgets/body_tracker_summary_header.dart';
import '../widgets/measurement_card.dart';

class BodyTrackerPage extends ConsumerStatefulWidget {
  const BodyTrackerPage({super.key});

  @override
  ConsumerState<BodyTrackerPage> createState() => _BodyTrackerPageState();
}

class _BodyTrackerPageState extends ConsumerState<BodyTrackerPage> {
  final Set<String> _expandedIds = {};
  String _filterMode = 'all'; // 'all', '30_days', '7_days'
  bool _showSummary = true;

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _toggleAll(List<String> allIds) {
    setState(() {
      if (_expandedIds.length == allIds.length) {
        _expandedIds.clear();
      } else {
        _expandedIds.addAll(allIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get the list of measurements
    final rawList = ref.watch(bodyTrackerProvider);
    final userProfileState = ref.watch(userProfileProvider);
    final userProfile = userProfileState.value;

    // Apply Filter
    final measurementList = rawList.where((m) {
      if (_filterMode == 'all') return true;
      final diff = DateTime.now().difference(m.date).inDays;
      if (_filterMode == '7_days') return diff <= 7;
      if (_filterMode == '30_days') return diff <= 30;
      if (_filterMode == '90_days') return diff <= 90;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                'Medidas',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _showSummary ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _showSummary = !_showSummary),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () => context.go('/body-tracker/add'),
              ),
            ],
          ),

          // SUMMARY HEADER
          if (measurementList.isNotEmpty && _showSummary)
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  BodyTrackerSummaryHeader(measurements: measurementList),
                ],
              ),
            ),

          // FILTERS
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Expand All Button
                  TextButton.icon(
                    onPressed: measurementList.isEmpty
                        ? null
                        : () => _toggleAll(
                            measurementList.map((e) => e.id).toList(),
                          ),
                    icon: Icon(
                      _expandedIds.length == measurementList.length
                          ? Icons.unfold_less
                          : Icons.unfold_more,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    label: Text(
                      _expandedIds.length == measurementList.length
                          ? "Recolher Tudo"
                          : "Expandir Tudo",
                      style: GoogleFonts.outfit(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),

                  // Filter Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: PopupMenuButton<String>(
                      initialValue: _filterMode,
                      onSelected: (value) =>
                          setState(() => _filterMode = value),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.filter_list,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _filterMode == 'all'
                                ? "Todas"
                                : (_filterMode == '30_days'
                                      ? "30 Dias"
                                      : (_filterMode == '90_days'
                                            ? "90 Dias"
                                            : "7 Dias")),
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.textSecondary,
                            size: 16,
                          ),
                        ],
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'all', child: Text("Todas")),
                        const PopupMenuItem(
                          value: '90_days',
                          child: Text("Últimos 90 dias"),
                        ),
                        const PopupMenuItem(
                          value: '30_days',
                          child: Text("Últimos 30 dias"),
                        ),
                        const PopupMenuItem(
                          value: '7_days',
                          child: Text("Últimos 7 dias"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // LIST
          if (measurementList.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.insights,
                      size: 64,
                      color: Colors.white.withOpacity(0.1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      rawList.isEmpty
                          ? 'Comece sua jornada.\nToque em + para registrar.'
                          : 'Nenhuma medida neste período.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final current = measurementList[index];
                // Compare with NEXT (older because sorted descending)
                final next = (index + 1 < measurementList.length)
                    ? measurementList[index + 1]
                    : null;

                final isExpanded = _expandedIds.contains(current.id);

                return MeasurementCard(
                  measurement: current,
                  previousMeasurement: next,
                  isExpanded: isExpanded,
                  onExpand: () => _toggleExpand(current.id),
                  onEdit: () {
                    context.push('/body-tracker/add', extra: current);
                  },
                  onDelete: () async {
                    final confirm = await AppDialogs.showConfirmDialog<bool>(
                      context: context,
                      title: "Excluir",
                      description:
                          "Tem certeza que deseja excluir este registro?",
                      confirmText: "EXCLUIR",
                      isDestructive: true,
                    );

                    if (confirm == true) {
                      ref
                          .read(bodyTrackerProvider.notifier)
                          .deleteMeasurement(current.id);
                    }
                  },
                  userHeight: userProfile?.height,
                );
              }, childCount: measurementList.length),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
