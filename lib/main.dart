import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart'; // Garante a integração com o tema do Ubuntu
import 'package:fl_chart/fl_chart.dart'; 
import 'services/system_usage_service.dart';

// 1. PONTO DE ENTRADA OBRIGATÓRIO
void main() {
  runApp(const MyApp());
}

// 2. WIDGET DE CONFIGURAÇÃO DA APLICAÇÃO
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return YaruTheme(
      builder: (context, yaru, child) {
        return MaterialApp(
          title: 'System Monitor Dash',
          theme: yaru.theme,
          darkTheme: yaru.darkTheme,
          home: const PerformanceDashboardPage(), // Define a página inicial
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

// 3. A SUA PÁGINA DE DESEMPENHO COM OS GRÁFICOS
class PerformanceDashboardPage extends StatefulWidget {
  const PerformanceDashboardPage({super.key});

  @override
  State<PerformanceDashboardPage> createState() => _PerformanceDashboardPageState();
}

class _PerformanceDashboardPageState extends State<PerformanceDashboardPage> {
  final _service = SystemUsageService();
  StreamSubscription<SystemMetrics>? _subscription;
  
  final List<FlSpot> _cpuHistory = [];
  final List<FlSpot> _memHistory = [];
  int _timeCounter = 0;

  @override
  void initState() {
    super.initState();
    _subscription = _service.metricsStream.listen((metrics) {
      setState(() {
        _updateHistory(metrics.cpuUsagePercentage, metrics.memoryUsagePercentage);
      });
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _updateHistory(double cpuValue, double memValue) {
    _timeCounter++;
    _cpuHistory.add(FlSpot(_timeCounter.toDouble(), cpuValue));
    _memHistory.add(FlSpot(_timeCounter.toDouble(), memValue));

    if (_cpuHistory.length > 30) _cpuHistory.removeAt(0);
    if (_memHistory.length > 30) _memHistory.removeAt(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desempenho do Sistema'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _cpuHistory.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: ListView(
                children: [
                  _buildMetricCard(
                    title: 'Processador (CPU)',
                    subtitle: '${_cpuHistory.last.y.toStringAsFixed(1)}%',
                    history: _cpuHistory,
                    lineColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  _buildMetricCard(
                    title: 'Memória RAM',
                    subtitle: '${_memHistory.last.y.toStringAsFixed(1)}%',
                    history: _memHistory,
                    lineColor: Colors.purple,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String subtitle,
    required List<FlSpot> history,
    required Color lineColor,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: lineColor, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  minX: _timeCounter > 30 ? (_timeCounter - 30).toDouble() : 0,
                  maxX: _timeCounter > 30 ? _timeCounter.toDouble() : 30,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: history,
                      isCurved: true,
                      barWidth: 2,
                      color: lineColor,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            lineColor.withOpacity(0.3),
                            lineColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}