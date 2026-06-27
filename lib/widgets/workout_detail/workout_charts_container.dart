import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/workout.dart';
import '../../theme/app_theme.dart';

class WorkoutChartsContainer extends StatefulWidget {
  final Workout workout;
  final ValueNotifier<LatLng?> trackingPinPositionNotifier;

  const WorkoutChartsContainer({
    super.key,
    required this.workout,
    required this.trackingPinPositionNotifier,
  });

  @override
  State<WorkoutChartsContainer> createState() => _WorkoutChartsContainerState();
}

class _WorkoutChartsContainerState extends State<WorkoutChartsContainer> {
  late final ValueNotifier<double?> _hoverDistanceNotifier;
  late final List<_ChartsSeriesPoint> _series;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _hoverDistanceNotifier = ValueNotifier<double?>(null);
    final double workoutDistance = widget.workout.distance ?? 0.0;
    final double avgPaceMins = workoutDistance > 0 ? (widget.workout.duration / workoutDistance) : 0.0;
    _series = _generateSeriesData(workoutDistance, avgPaceMins);
    _parseRoutePoints();
  }

  @override
  void dispose() {
    _hoverDistanceNotifier.dispose();
    super.dispose();
  }

  void _parseRoutePoints() {
    if (widget.workout.polyline != null && widget.workout.polyline!.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(widget.workout.polyline!);
        _routePoints = decoded.map((p) => LatLng(
          (p[0] as num).toDouble(),
          (p[1] as num).toDouble(),
        )).toList();
      } catch (e) {
        // ignore
      }
    }
  }

  void _handleTouch(FlTouchEvent event, LineTouchResponse? response) {
    if (!event.isInterestedForInteractions || response == null || response.lineBarSpots == null || response.lineBarSpots!.isEmpty) {
      _hoverDistanceNotifier.value = null;
      widget.trackingPinPositionNotifier.value = null;
      return;
    }

    final spot = response.lineBarSpots!.first;
    final double touchedKm = spot.x;
    _hoverDistanceNotifier.value = touchedKm;

    if (_routePoints.isNotEmpty) {
      final totalDist = widget.workout.distance ?? 5.0;
      if (totalDist > 0) {
        double progress = (touchedKm / totalDist).clamp(0.0, 1.0);
        int index = (progress * (_routePoints.length - 1)).round();
        widget.trackingPinPositionNotifier.value = _routePoints[index];
      }
    }
  }

  int _findClosestSpotIndex(double hoverDistance) {
    double minDiff = double.maxFinite;
    int closestIdx = 0;
    for (int i = 0; i < _series.length; i++) {
      final diff = (_series[i].distance - hoverDistance).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIdx = i;
      }
    }
    return closestIdx;
  }

  @override
  Widget build(BuildContext context) {
    final double workoutDistance = widget.workout.distance ?? 0.0;
    final double avgPaceMins = workoutDistance > 0 ? (widget.workout.duration / workoutDistance) : 0.0;

    return ValueListenableBuilder<double?>(
      valueListenable: _hoverDistanceNotifier,
      builder: (context, hoverDist, _) {
        final int? activeIndex = hoverDist != null ? _findClosestSpotIndex(hoverDist) : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Pace'),
            _buildChartFrame(
              chart: _buildPaceChart(activeIndex, avgPaceMins),
              stats: _buildPaceStats(avgPaceMins),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Heart Rate'),
            _buildChartFrame(chart: _buildHeartRateChart(activeIndex)),
            const SizedBox(height: 24),

            _buildSectionHeader('Power'),
            _buildChartFrame(chart: _buildPowerChart(activeIndex)),
            const SizedBox(height: 24),

            _buildSectionHeader('Cadence'),
            _buildChartFrame(chart: _buildCadenceChart(activeIndex)),
            const SizedBox(height: 24),

            _buildSectionHeader('Elevation'),
            _buildChartFrame(chart: _buildElevationChart(activeIndex)),
          ],
        );
      }
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        title,
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
      ),
    );
  }

  Widget _buildChartFrame({required Widget chart, Widget? stats}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            SizedBox(height: 160, child: chart),
            if (stats != null) ...[
              const SizedBox(height: 12),
              stats,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaceChart(int? activeIndex, double avgPaceMins) {
    final spots = _series.map((s) => FlSpot(s.distance, 15.0 - s.pace)).toList();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: widget.workout.distance ?? 5.0,
        minY: 5.0,
        maxY: 12.0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 2.0,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.textPrimary.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          touchCallback: _handleTouch,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => const Color(0xFF00A9DD),
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                final double origPace = 15.0 - s.y;
                final m = origPace.truncate();
                final sec = ((origPace - m) * 60).round().toString().padLeft(2, '0');
                return LineTooltipItem(
                  "$m:$sec /km\n${s.x.toStringAsFixed(2)} km",
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        showingTooltipIndicators: activeIndex != null ? [
          ShowingTooltipIndicators([
            LineBarSpot(
              LineChartBarData(spots: spots),
              0,
              spots[activeIndex],
            ),
          ]),
        ] : [],
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 15.0 - avgPaceMins,
              color: Colors.grey.withOpacity(0.5),
              strokeWidth: 1.5,
              dashArray: [5, 5],
            ),
          ],
          verticalLines: [
            if (activeIndex != null)
              VerticalLine(
                x: _series[activeIndex].distance,
                color: Colors.grey.withOpacity(0.8),
                strokeWidth: 1.5,
                dashArray: [5, 5],
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF00A9DD),
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF00A9DD).withOpacity(0.2),
                  const Color(0xFF00A9DD).withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateChart(int? activeIndex) {
    final spots = _series.map((s) => FlSpot(s.distance, s.heartRate)).toList();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: widget.workout.distance ?? 5.0,
        minY: 100.0,
        maxY: 200.0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.textPrimary.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          touchCallback: _handleTouch,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Colors.redAccent,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                return LineTooltipItem(
                  "${s.y.round()} bpm\n${s.x.toStringAsFixed(2)} km",
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        showingTooltipIndicators: activeIndex != null ? [
          ShowingTooltipIndicators([
            LineBarSpot(
              LineChartBarData(spots: spots),
              0,
              spots[activeIndex],
            ),
          ]),
        ] : [],
        extraLinesData: ExtraLinesData(
          verticalLines: [
            if (activeIndex != null)
              VerticalLine(
                x: _series[activeIndex].distance,
                color: Colors.grey.withOpacity(0.8),
                strokeWidth: 1.5,
                dashArray: [5, 5],
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.redAccent,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.redAccent.withOpacity(0.2),
                  Colors.redAccent.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerChart(int? activeIndex) {
    final spots = _series.map((s) => FlSpot(s.distance, s.power)).toList();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: widget.workout.distance ?? 5.0,
        minY: 100.0,
        maxY: 400.0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.textPrimary.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          touchCallback: _handleTouch,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Colors.deepPurpleAccent,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                return LineTooltipItem(
                  "${s.y.round()} W\n${s.x.toStringAsFixed(2)} km",
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        showingTooltipIndicators: activeIndex != null ? [
          ShowingTooltipIndicators([
            LineBarSpot(
              LineChartBarData(spots: spots),
              0,
              spots[activeIndex],
            ),
          ]),
        ] : [],
        extraLinesData: ExtraLinesData(
          verticalLines: [
            if (activeIndex != null)
              VerticalLine(
                x: _series[activeIndex].distance,
                color: Colors.grey.withOpacity(0.8),
                strokeWidth: 1.5,
                dashArray: [5, 5],
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.deepPurpleAccent,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.deepPurpleAccent.withOpacity(0.2),
                  Colors.deepPurpleAccent.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCadenceChart(int? activeIndex) {
    final spots = _series.map((s) => FlSpot(s.distance, s.cadence)).toList();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: widget.workout.distance ?? 5.0,
        minY: 130.0,
        maxY: 195.0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.textPrimary.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          touchCallback: _handleTouch,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Colors.grey[700]!,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                return LineTooltipItem(
                  "${s.y.round()} spm\n${s.x.toStringAsFixed(2)} km",
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        showingTooltipIndicators: activeIndex != null ? [
          ShowingTooltipIndicators([
            LineBarSpot(
              LineChartBarData(spots: spots),
              0,
              spots[activeIndex],
            ),
          ]),
        ] : [],
        extraLinesData: ExtraLinesData(
          verticalLines: [
            if (activeIndex != null)
              VerticalLine(
                x: _series[activeIndex].distance,
                color: Colors.grey.withOpacity(0.8),
                strokeWidth: 1.5,
                dashArray: [5, 5],
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.grey[400]!,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[400]!.withOpacity(0.2),
                  Colors.grey[400]!.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElevationChart(int? activeIndex) {
    final spots = _series.map((s) => FlSpot(s.distance, s.elevation)).toList();

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: widget.workout.distance ?? 5.0,
        minY: 0.0,
        maxY: 120.0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.textPrimary.withOpacity(0.06),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          touchCallback: _handleTouch,
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => Colors.blueGrey,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((s) {
                return LineTooltipItem(
                  "${s.y.round()} m\n${s.x.toStringAsFixed(2)} km",
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList();
            },
          ),
        ),
        showingTooltipIndicators: activeIndex != null ? [
          ShowingTooltipIndicators([
            LineBarSpot(
              LineChartBarData(spots: spots),
              0,
              spots[activeIndex],
            ),
          ]),
        ] : [],
        extraLinesData: ExtraLinesData(
          verticalLines: [
            if (activeIndex != null)
              VerticalLine(
                x: _series[activeIndex].distance,
                color: Colors.grey.withOpacity(0.8),
                strokeWidth: 1.5,
                dashArray: [5, 5],
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueGrey[700]!,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blueGrey.withOpacity(0.25),
                  Colors.blueGrey.withOpacity(0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaceStats(double avgPaceMins) {
    String formatPace(double paceVal) {
      final m = paceVal.truncate();
      final s = ((paceVal - m) * 60).round().toString().padLeft(2, '0');
      return '$m:$s';
    }

    final totalSeconds = (widget.workout.duration * 60).round();
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final movingTimeStr = h > 0 
        ? "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}" 
        : "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statLabelValue('Avg Pace', '${formatPace(avgPaceMins)} /km'),
              _statLabelValue('Moving Time', movingTimeStr),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statLabelValue('Avg Elapsed Pace', '${formatPace(avgPaceMins * 1.1)} /km'),
              _statLabelValue('Elapsed Time', '${(widget.workout.duration * 1.05).round()}m'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statLabelValue('Fastest Split', '5:32 /km'),
              const SizedBox.shrink(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statLabelValue(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        Text(value, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  List<_ChartsSeriesPoint> _generateSeriesData(double dist, double avgPace) {
    final double actualDist = dist > 0 ? dist : 5.0;
    final double actualPace = avgPace > 0 ? avgPace : 7.0;
    final List<_ChartsSeriesPoint> list = [];
    const int count = 25;

    for (int i = 0; i <= count; i++) {
      final d = (actualDist / count) * i;
      final factor = 1.0 + 0.05 * (i % 4 - 2);
      final p = actualPace * factor;
      final elev = 35.0 + 15.0 * (i % 6 - 3) + (i % 3) * 2;
      final slope = (i == 0) ? 0.0 : (elev - list.last.elevation);
      final gap = p - (slope * 0.04);
      final cad = 171.0 + 3.0 * (i % 5 - 2);
      final hr = 138.0 + 12.0 * (i / count);
      final power = 210.0 + 30.0 * (i % 3 - 1) + (slope * 5);

      list.add(_ChartsSeriesPoint(
        distance: d,
        pace: p.clamp(3.0, 15.0),
        gap: gap.clamp(3.0, 15.0),
        cadence: cad.clamp(140.0, 200.0),
        elevation: elev.clamp(0.0, 200.0),
        heartRate: hr.clamp(100.0, 190.0),
        power: power.clamp(100.0, 450.0),
      ));
    }
    return list;
  }
}

class _ChartsSeriesPoint {
  final double distance;
  final double pace;
  final double gap;
  final double cadence;
  final double elevation;
  final double heartRate;
  final double power;

  _ChartsSeriesPoint({
    required this.distance,
    required this.pace,
    required this.gap,
    required this.cadence,
    required this.elevation,
    required this.heartRate,
    required this.power,
  });
}
