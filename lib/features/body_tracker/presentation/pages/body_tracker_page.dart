import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/body_tracker_provider.dart';
import '../../../../core/constants/app_colors.dart';

class BodyTrackerPage extends ConsumerStatefulWidget {
  const BodyTrackerPage({super.key});

  @override
  ConsumerState<BodyTrackerPage> createState() => _BodyTrackerPageState();
}

class _BodyTrackerPageState extends ConsumerState<BodyTrackerPage> {
  final Set<String> _expandedIds = {};
  String _filterMode = 'all'; // 'all', '30_days', '7_days'

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
    // Note: Variable name is 'measurementList' to match usage below
    final rawList = ref.watch(bodyTrackerProvider);

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
      appBar: AppBar(title: const Text('Medidas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/body-tracker/add'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Column(
        children: [
          // HEADER: Filters and Expand All
          Padding(
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
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                  ),
                  label: Text(
                    _expandedIds.length == measurementList.length
                        ? "Recolher Todas"
                        : "Expandir Todas",
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),

                // Filter Dropdown
                PopupMenuButton<String>(
                  initialValue: _filterMode,
                  onSelected: (value) => setState(() => _filterMode = value),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        _filterMode == 'all'
                            ? "Todas"
                            : (_filterMode == '30_days' ? "30 Dias" : "7 Dias"),
                        style: const TextStyle(color: Colors.white),
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
              ],
            ),
          ),

          // LIST
          Expanded(
            child: measurementList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.accessibility_new,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          rawList.isEmpty
                              ? 'Nenhuma medida registrada.\nToque em + para começar.'
                              : 'Nenhuma medida neste período.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: measurementList.length,
                    itemBuilder: (context, index) {
                      final current = measurementList[index];
                      // Compare with NEXT (older because sorted descending)
                      final next = (index + 1 < measurementList.length)
                          ? measurementList[index + 1]
                          : null;

                      final isExpanded = _expandedIds.contains(current.id);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'dd/MM/yyyy',
                                    ).format(current.date),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),

                                  // 3-Dots Menu
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        context.push(
                                          '/body-tracker/add',
                                          extra: current,
                                        );
                                      } else if (value == 'delete') {
                                        // Delete
                                        final confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                            title: const Text("Excluir"),
                                            content: const Text(
                                              "Tem certeza que deseja excluir este registro?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, false),
                                                child: const Text("Cancelar"),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx, true),
                                                child: const Text(
                                                  "Excluir",
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          ref
                                              .read(
                                                bodyTrackerProvider.notifier,
                                              )
                                              .deleteMeasurement(current.id);
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text("Editar"),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete,
                                              size: 20,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              "Excluir",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // WEIGHT ROW
                              Row(
                                children: [
                                  Text(
                                    '${current.weight} kg',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                  if (next != null)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Icon(
                                        current.weight < next.weight
                                            ? Icons.arrow_drop_up
                                            : (current.weight > next.weight
                                                  ? Icons.arrow_drop_down
                                                  : Icons.remove),
                                        color: current.weight < next.weight
                                            ? Colors.green
                                            : (current.weight > next.weight
                                                  ? Colors.red
                                                  : Colors.grey),
                                        size: 24,
                                      ),
                                    ),
                                ],
                              ),

                              // Collapsible Content
                              const SizedBox(height: 8),

                              // BMI SECTION (Always Visible)
                              if (current.bmi != null) ...[
                                const Divider(),
                                _buildBMISection(context, current.bmi!),
                                const SizedBox(height: 12),
                              ],

                              // Collapsible Content
                              if (isExpanded) ...[
                                const Divider(),
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 8,
                                  children: [
                                    if (current.waistCircumference > 0)
                                      _buildMeasureItem(
                                        context,
                                        'Cintura',
                                        current.waistCircumference,
                                        next?.waistCircumference,
                                        lowerIsBetter: true,
                                      ),
                                    if (current.hipsCircumference != null &&
                                        current.hipsCircumference! > 0)
                                      _buildMeasureItem(
                                        context,
                                        'Quadril',
                                        current.hipsCircumference!,
                                        next?.hipsCircumference,
                                        lowerIsBetter: true,
                                      ),
                                    if (current.chestCircumference > 0)
                                      _buildMeasureItem(
                                        context,
                                        'Peitoral',
                                        current.chestCircumference,
                                        next?.chestCircumference,
                                        lowerIsBetter: false,
                                      ),
                                    if (current.bicepsRight > 0)
                                      _buildMeasureItem(
                                        context,
                                        'Bíceps (Dir.)',
                                        current.bicepsRight,
                                        next?.bicepsRight,
                                        lowerIsBetter: false,
                                      ),
                                    if (current.bicepsLeft > 0)
                                      _buildMeasureItem(
                                        context,
                                        'Bíceps (Esq.)',
                                        current.bicepsLeft,
                                        next?.bicepsLeft,
                                        lowerIsBetter: false,
                                      ),
                                    if (current.thighRight != null &&
                                        current.thighRight! > 0)
                                      _buildMeasureItem(
                                        context,
                                        'Coxa (Dir.)',
                                        current.thighRight!,
                                        next?.thighRight,
                                        lowerIsBetter: false,
                                      ),
                                    if (current.thighLeft != null &&
                                        current.thighLeft! > 0)
                                      _buildMeasureItem(
                                        context,
                                        'Coxa (Esq.)',
                                        current.thighLeft!,
                                        next?.thighLeft,
                                        lowerIsBetter: false,
                                      ),
                                    if (current.calvesRight != null &&
                                        current.calvesRight! > 0)
                                      _buildMeasureItem(
                                        context,
                                        'Pant. (Dir.)',
                                        current.calvesRight!,
                                        next?.calvesRight,
                                        lowerIsBetter: false,
                                      ),
                                    if (current.calvesLeft != null &&
                                        current.calvesLeft! > 0)
                                      _buildMeasureItem(
                                        context,
                                        'Pant. (Esq.)',
                                        current.calvesLeft!,
                                        next?.calvesLeft,
                                        lowerIsBetter: false,
                                      ),
                                    if (current.neck != null &&
                                        current.neck! > 0)
                                      _buildMeasureItem(
                                        context,
                                        'Pescoço',
                                        current.neck!,
                                        next?.neck,
                                        lowerIsBetter: false,
                                      ),
                                    if (current.shoulders != null &&
                                        current.shoulders! > 0)
                                      _buildMeasureItem(
                                        context,
                                        'Ombros',
                                        current.shoulders!,
                                        next?.shoulders,
                                        lowerIsBetter: false,
                                      ),
                                    if (current.forearmRight != null &&
                                        current.forearmRight! > 0)
                                      _buildMeasureItem(
                                        context,
                                        'Ante. (Dir.)',
                                        current.forearmRight!,
                                        next?.forearmRight,
                                        lowerIsBetter: false,
                                      ),
                                    if (current.forearmLeft != null &&
                                        current.forearmLeft! > 0)
                                      _buildMeasureItem(
                                        context,
                                        'Ante. (Esq.)',
                                        current.forearmLeft!,
                                        next?.forearmLeft,
                                        lowerIsBetter: false,
                                      ),
                                  ],
                                ),
                              ],

                              // Expand Button (Right Aligned)
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    onPressed: () => _toggleExpand(current.id),
                                    icon: Icon(
                                      isExpanded
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getBMIGrade(double bmi) {
    if (bmi < 18.5) return "Abaixo do Peso";
    if (bmi < 24.9) return "Peso Normal";
    if (bmi < 29.9) return "Sobrepeso";
    if (bmi < 34.9) return "Obesidade I";
    if (bmi < 39.9) return "Obesidade II";
    return "Obesidade III";
  }

  Color _getBMIColor(double bmi) {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 24.9) return Colors.green;
    if (bmi < 29.9) return Colors.yellow;
    if (bmi < 34.9) return Colors.orange;
    if (bmi < 39.9) return Colors.deepOrange;
    return Colors.red;
  }

  Widget _buildBMISection(BuildContext context, double bmi) {
    final grade = _getBMIGrade(bmi);
    final color = _getBMIColor(bmi);
    // Normalized for bar (approx range 15-40)
    final progress = ((bmi - 15) / (40 - 15)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "IMC: ${bmi.toStringAsFixed(1)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              grade,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Gradient Bar
        SizedBox(
          height: 12,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final markerPosition = progress * width;

              return Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: const LinearGradient(
                        colors: [
                          Colors.blue,
                          Colors.green,
                          Colors.yellow,
                          Colors.orange,
                          Colors.red,
                        ],
                        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (markerPosition - 2).clamp(0.0, width - 4),
                    top: 0,
                    bottom: 0, // Fill stack height (12) but bar is 8... wait.
                    child: Center(
                      child: Container(
                        width: 4,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: Colors.black, width: 1),
                          boxShadow: const [
                            BoxShadow(color: Colors.black45, blurRadius: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMeasureItem(
    BuildContext context,
    String label,
    double value,
    double? previousValue, {
    bool lowerIsBetter = false,
    int digits = 0,
  }) {
    Color? trendColor;
    IconData? trendIcon;

    if (previousValue != null) {
      if (value > previousValue) {
        trendIcon = Icons.arrow_drop_up;
        trendColor = lowerIsBetter ? Colors.red : Colors.green;
      } else if (value < previousValue) {
        trendIcon = Icons.arrow_drop_down;
        trendColor = lowerIsBetter ? Colors.green : Colors.red;
      } else {
        trendIcon = Icons.remove;
        trendColor = Colors.grey;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toStringAsFixed(digits),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (trendIcon != null) Icon(trendIcon, color: trendColor, size: 16),
          ],
        ),
      ],
    );
  }
}
