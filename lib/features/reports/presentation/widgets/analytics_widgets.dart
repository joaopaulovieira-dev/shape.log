import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class VolumeChart extends StatelessWidget {
  final List<MapEntry<DateTime, double>> volumeData;

  const VolumeChart({super.key, required this.volumeData});

  @override
  Widget build(BuildContext context) {
    if (volumeData.isEmpty) {
      return const Center(child: Text("Sem dados de volume"));
    }

    final sortedData = List.of(volumeData)
      ..sort((a, b) => a.key.compareTo(b.key));
    // Limit to last 10 sessions for clarity
    final displayData = sortedData.length > 10
        ? sortedData.sublist(sortedData.length - 10)
        : sortedData;

    final maxY = displayData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    final interval = maxY > 0 ? maxY / 4 : 1.0;

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: interval,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return const FlLine(color: Colors.white10, strokeWidth: 1);
              },
              getDrawingVerticalLine: (value) {
                return const FlLine(color: Colors.white10, strokeWidth: 1);
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= displayData.length)
                      return const SizedBox.shrink();
                    final date = displayData[index].key;
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        DateFormat('dd/MM').format(date),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: interval,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${(value / 1000).toStringAsFixed(1)}k',
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                      textAlign: TextAlign.left,
                    );
                  },
                  reservedSize: 30,
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xff37434d)),
            ),
            minX: 0,
            maxX: (displayData.length - 1).toDouble(),
            minY: 0,
            maxY: maxY * 1.1,
            lineBarsData: [
              LineChartBarData(
                spots: displayData.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.value);
                }).toList(),
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.5),
                    AppColors.primary,
                  ],
                ),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.3),
                      AppColors.primary.withOpacity(0.0),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FrequencyChart extends StatelessWidget {
  final List<int> frequencyData; // 7 days (Sun-Sat), count per day OR boolean

  const FrequencyChart({super.key, required this.frequencyData});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => Colors.blueGrey,
                tooltipHorizontalAlignment: FLHorizontalAlignment.center,
                tooltipMargin: -10,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  String weekDay;
                  switch (group.x) {
                    case 0:
                      weekDay = 'Dom';
                      break;
                    case 1:
                      weekDay = 'Seg';
                      break;
                    case 2:
                      weekDay = 'Ter';
                      break;
                    case 3:
                      weekDay = 'Qua';
                      break;
                    case 4:
                      weekDay = 'Qui';
                      break;
                    case 5:
                      weekDay = 'Sex';
                      break;
                    case 6:
                      weekDay = 'Sab';
                      break;
                    default:
                      throw Error();
                  }
                  return BarTooltipItem(
                    '$weekDay\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: (rod.toY.toInt()).toString(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    const style = TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    );
                    Widget text;
                    switch (value.toInt()) {
                      case 0:
                        text = const Text('D', style: style);
                        break;
                      case 1:
                        text = const Text('S', style: style);
                        break;
                      case 2:
                        text = const Text('T', style: style);
                        break;
                      case 3:
                        text = const Text('Q', style: style);
                        break;
                      case 4:
                        text = const Text('Q', style: style);
                        break;
                      case 5:
                        text = const Text('S', style: style);
                        break;
                      case 6:
                        text = const Text('S', style: style);
                        break;
                      default:
                        text = const Text('', style: style);
                        break;
                    }
                    return SideTitleWidget(meta: meta, space: 4, child: text);
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(7, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: index < frequencyData.length
                        ? frequencyData[index].toDouble()
                        : 0.0,
                    color:
                        (index < frequencyData.length &&
                            frequencyData[index] > 0)
                        ? AppColors.primary
                        : Colors.grey.withOpacity(0.2),
                    width: 20,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              );
            }),
            gridData: const FlGridData(show: false),
            alignment: BarChartAlignment.spaceAround,
            maxY: 2, // Binary (0 or 1) mostly, or 2 if multiple workouts
          ),
        ),
      ),
    );
  }
}
