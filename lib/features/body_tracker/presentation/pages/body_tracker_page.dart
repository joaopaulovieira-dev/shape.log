import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/body_tracker_provider.dart';
import '../../../profile/presentation/providers/user_profile_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/presentation/widgets/app_dialogs.dart';
import '../../../../core/presentation/widgets/app_empty_state.dart';
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

    if (kIsWeb) {
      return _buildWebLayout(context, measurementList);
    }

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
              hasScrollBody: false,
              child: rawList.isEmpty
                  ? AppEmptyState(
                      icon: Icons.insights_rounded,
                      title: 'Nenhuma medida registrada',
                      subtitle:
                          'Registre suas medidas corporais para acompanhar sua evolução física ao longo do tempo.',
                      actionLabel: 'Registrar Medida',
                      onActionPressed: () => context.go('/body-tracker/add'),
                    )
                  : const AppEmptyState(
                      icon: Icons.filter_list_off_rounded,
                      title: 'Nenhuma medida no período',
                      subtitle:
                          'Não encontramos registros de medidas corporais para o filtro selecionado.',
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


  // ─────────────────────────────────────────────────────────────────────────
  // Web layout SaaS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildWebLayout(BuildContext context, List measurements) {
    final latest  = measurements.isNotEmpty ? measurements.first  : null;
    final prev    = measurements.length > 1  ? measurements[1]    : null;

    double? delta(double? Function(dynamic) fn) {
      if (latest == null || prev == null) return null;
      final a = fn(latest);
      final b = fn(prev);
      if (a == null || b == null) return null;
      return a - b;
    }

    final weightHistory = measurements
        .take(12)
        .map<double>((m) => (m.weight as double?) ?? 0.0)
        .toList()
        .reversed
        .toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // ── Painel lateral esquerdo 300px ─────────────────────────────────
          Container(
            width: 300,
            color: const Color(0xFF0A0A0A),
            child: Column(children: [
              // Botão
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.push('/body-tracker/add'),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Nova Medida',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: latest == null
                      ? const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text('Nenhuma medida ainda.',
                                style: TextStyle(color: Colors.white24)),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // KPI Cards
                            _SideLabel('ÚLTIMA MEDIDA'),
                            const SizedBox(height: 10),
                            _MiniKpi('Peso',
                                '${(latest.weight as double?)?.toStringAsFixed(1) ?? '—'} kg',
                                delta((m) => m.weight), 'kg', invert: true),
                            const SizedBox(height: 8),
                            _MiniKpi('IMC',
                                (latest.bmi as double?) != null
                                    ? (latest.bmi as double).toStringAsFixed(1)
                                    : '—',
                                delta((m) => m.bmi), '', invert: true),
                            if (latest.fatPercentage != null) ...[
                              const SizedBox(height: 8),
                              _MiniKpi('Gordura',
                                  '${(latest.fatPercentage as double).toStringAsFixed(1)}%',
                                  delta((m) => m.fatPercentage), '%',
                                  invert: true),
                            ],
                            if (latest.muscleMassKg != null) ...[
                              const SizedBox(height: 8),
                              _MiniKpi('Massa muscular',
                                  '${(latest.muscleMassKg as double).toStringAsFixed(1)} kg',
                                  delta((m) => m.muscleMassKg), 'kg',
                                  invert: false),
                            ],
                            if (latest.waterPercentage != null) ...[
                              const SizedBox(height: 8),
                              _MiniKpi('Água corporal',
                                  '${(latest.waterPercentage as double).toStringAsFixed(1)}%',
                                  null, '%', invert: false),
                            ],
                            const SizedBox(height: 24),

                            // Sparkline evolução peso
                            if (weightHistory.length > 1) ...[
                              _SideLabel('EVOLUÇÃO DO PESO'),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF111111),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.07)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                        height: 80,
                                        child: _WeightSparkline(
                                            data: weightHistory)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                            'Início: ${weightHistory.first.toStringAsFixed(1)} kg',
                                            style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                color: Colors.white38)),
                                        Text(
                                            'Atual: ${weightHistory.last.toStringAsFixed(1)} kg',
                                            style: GoogleFonts.outfit(
                                                fontSize: 10,
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Circunferências vs anterior
                            _SideLabel('CIRCUNFERÊNCIAS'),
                            const SizedBox(height: 10),
                            ...[
                              ('Cintura', (dynamic m) => m.waistCircumference as double?),
                              ('Tórax',   (dynamic m) => m.chestCircumference as double?),
                              ('Quadril', (dynamic m) => m.hipsCircumference  as double?),
                              ('Bíceps D',(dynamic m) => m.bicepsRight        as double?),
                              ('Coxa D',  (dynamic m) => m.thighRight         as double?),
                            ].map((pair) {
                              final val = pair.$2(latest);
                              if (val == null) return const SizedBox.shrink();
                              final d = prev != null
                                  ? (() {
                                      final p = pair.$2(prev);
                                      return p != null ? val - p : null;
                                    })()
                                  : null;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 7),
                                child: Row(children: [
                                  Text(pair.$1,
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Colors.white54)),
                                  const Spacer(),
                                  Text('${val.toStringAsFixed(1)} cm',
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600)),
                                  if (d != null) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${d > 0 ? '+' : ''}${d.toStringAsFixed(1)}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        color: d < 0
                                            ? AppColors.primary
                                            : d > 0
                                                ? Colors.redAccent
                                                : Colors.white24,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ]),
                              );
                            }),
                          ],
                        ),
                ),
              ),
            ]),
          ),

          Container(width: 1, color: Colors.white.withOpacity(0.06)),

          // ── Tabela principal ──────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 14),
                  child: Text(
                    '${measurements.length} registro${measurements.length != 1 ? 's' : ''}',
                    style: GoogleFonts.outfit(
                        color: Colors.white38, fontSize: 13),
                  ),
                ),
                // Header tabela
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0D),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.07)),
                    ),
                    child: Row(children: [
                      _Col('Data',       flex: 2),
                      _Col('Peso (kg)',  flex: 1),
                      _Col('IMC',        flex: 1),
                      _Col('Cintura cm', flex: 1),
                      _Col('Bíceps D/E', flex: 2),
                      _Col('Gordura %',  flex: 1),
                      _Col('',           flex: 1),
                    ]),
                  ),
                ),
                const SizedBox(height: 6),

                // Linhas
                if (measurements.isEmpty)
                  Expanded(
                    child: AppEmptyState(
                      icon: Icons.monitor_weight_outlined,
                      title: 'Nenhuma medida',
                      subtitle: 'Adicione sua primeira medida corporal.',
                      actionLabel: 'Adicionar',
                      onActionPressed: () =>
                          context.push('/body-tracker/add'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                      itemCount: measurements.length,
                      separatorBuilder: (_, i) =>
                          const SizedBox(height: 5),
                      itemBuilder: (context, index) {
                        final m    = measurements[index];
                        final isFirst = index == 0;
                        final d    = m.date as DateTime;
                        final dateStr =
                            '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

                        // bmi badge color
                        final bmi = m.bmi as double?;
                        Color bmiColor = Colors.white38;
                        String bmiLabel = bmi?.toStringAsFixed(1) ?? '—';
                        if (bmi != null) {
                          if (bmi < 18.5)       bmiColor = Colors.blueAccent;
                          else if (bmi < 25.0)  bmiColor = AppColors.primary;
                          else if (bmi < 30.0)  bmiColor = Colors.orangeAccent;
                          else                  bmiColor = Colors.redAccent;
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isFirst
                                ? AppColors.primary.withOpacity(0.05)
                                : const Color(0xFF111111),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isFirst
                                  ? AppColors.primary.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Row(children: [
                            Expanded(
                              flex: 2,
                              child: Row(children: [
                                Text(dateStr,
                                    style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: isFirst
                                            ? FontWeight.w600
                                            : FontWeight.w400)),
                                if (isFirst) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(4),
                                    ),
                                    child: Text('ATUAL',
                                        style: GoogleFonts.outfit(
                                          fontSize: 8,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                        )),
                                  ),
                                ],
                              ]),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${(m.weight as double?)?.toStringAsFixed(1) ?? '—'}',
                                style: GoogleFonts.outfit(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: bmiColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  child: Text(bmiLabel,
                                      style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: bmiColor,
                                          fontWeight: FontWeight.w600)),
                                ),
                              ]),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${(m.waistCircumference as double?)?.toStringAsFixed(1) ?? '—'}',
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${(m.bicepsRight as double?)?.toStringAsFixed(1) ?? '—'} / ${(m.bicepsLeft as double?)?.toStringAsFixed(1) ?? '—'}',
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                (m.fatPercentage as double?) != null
                                    ? '${(m.fatPercentage as double).toStringAsFixed(1)}%'
                                    : '—',
                                style: GoogleFonts.outfit(
                                    color: Colors.white70, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Row(children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 15, color: Colors.white38),
                                  onPressed: () => context
                                      .push('/body-tracker/add', extra: m),
                                  tooltip: 'Editar',
                                  visualDensity: VisualDensity.compact,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 15, color: Colors.redAccent),
                                  onPressed: () async {
                                    final ok =
                                        await AppDialogs.showConfirmDialog<
                                            bool>(
                                      context: context,
                                      title: 'Excluir medida?',
                                      description:
                                          'Esta ação não pode ser desfeita.',
                                      confirmText: 'EXCLUIR',
                                      isDestructive: true,
                                    );
                                    if (ok == true) {
                                      ref
                                          .read(
                                              bodyTrackerProvider.notifier)
                                          .deleteMeasurement(
                                              m.id as String);
                                    }
                                  },
                                  tooltip: 'Excluir',
                                  visualDensity: VisualDensity.compact,
                                ),
                              ]),
                            ),
                          ]),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _SideLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 0),
        child: Text(text,
            style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white24,
                letterSpacing: 1.2)),
      );
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────────

class _MiniKpi extends StatelessWidget {
  final String label;
  final String value;
  final double? delta;
  final String unit;
  final bool invert;

  const _MiniKpi(this.label, this.value, this.delta, this.unit,
      {required this.invert});

  @override
  Widget build(BuildContext context) {
    Color? deltaColor;
    String? deltaStr;
    if (delta != null && delta != 0) {
      final improved = invert ? delta! < 0 : delta! > 0;
      deltaColor = improved ? AppColors.primary : Colors.redAccent;
      deltaStr =
          '${delta! > 0 ? '+' : ''}${delta!.toStringAsFixed(1)}$unit';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Row(children: [
        Text(label,
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54)),
        const Spacer(),
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white)),
        if (deltaStr != null) ...[
          const SizedBox(width: 6),
          Text(deltaStr,
              style: GoogleFonts.outfit(
                  fontSize: 10,
                  color: deltaColor,
                  fontWeight: FontWeight.w600)),
        ],
      ]),
    );
  }
}

class _Col extends StatelessWidget {
  final String label;
  final int flex;
  const _Col(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) => Expanded(
        flex: flex,
        child: Text(label,
            style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white38,
                letterSpacing: 0.4)),
      );
}

// ── Sparkline do peso ──────────────────────────────────────────────────────────

class _WeightSparkline extends StatelessWidget {
  final List<double> data;
  const _WeightSparkline({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(data: data),
      size: const Size(double.infinity, 80),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  _SparklinePainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final minY = data.reduce((a, b) => a < b ? a : b);
    final maxY = data.reduce((a, b) => a > b ? a : b);
    final rangeY = maxY - minY == 0 ? 1.0 : maxY - minY;

    double x(int i) => size.width * i / (data.length - 1);
    double y(double v) =>
        size.height - (size.height * 0.1) -
        ((v - minY) / rangeY) * (size.height * 0.8);

    final path = Path();
    path.moveTo(x(0), y(data[0]));
    for (int i = 1; i < data.length; i++) {
      final cx = (x(i - 1) + x(i)) / 2;
      path.cubicTo(cx, y(data[i - 1]), cx, y(data[i]), x(i), y(data[i]));
    }

    // Preenchimento
    final fillPath = Path.from(path);
    fillPath.lineTo(x(data.length - 1), size.height);
    fillPath.lineTo(x(0), size.height);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFCCFF00).withOpacity(0.2),
        const Color(0xFFCCFF00).withOpacity(0.0),
      ],
    );
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = gradient.createShader(
            Rect.fromLTWH(0, 0, size.width, size.height))
        ..style = PaintingStyle.fill,
    );

    // Linha
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFCCFF00)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Ponto final
    canvas.drawCircle(
      Offset(x(data.length - 1), y(data.last)),
      4,
      Paint()..color = const Color(0xFFCCFF00),
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.data != data;
}
