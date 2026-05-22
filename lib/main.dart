import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Importa a biblioteca de gráficos
import 'services/system_usage_service.dart';

class PerformanceDashboardPage extends StatefulWidget {
  const PerformanceDashboardPage({super.key});

  @override
  State<PerformanceDashboardPage> createState() =>
      _PerformanceDashboardPageState();
}

class _PerformanceDashboardPageState extends State<PerformanceDashboardPage> {
  final _service = SystemUsageService();

  final List<FlSpot> _cpuHistory = [];
  final List<FlSpot> _memHistory = [];
  int _timeCounter = 0;

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
      body: StreamBuilder<SystemMetrics>(
        stream: _service.metricsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _cpuHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data != null) {
            final metrics = snapshot.data!;
            _updateHistory(
              metrics.cpuUsagePercentage,
              metrics.memoryUsagePercentage,
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: ListView(
              children: [
                _buildMetricCard(
                  title: 'Processador (CPU)',
                  subtitle: _cpuHistory.isNotEmpty
                      ? '${_cpuHistory.last.y.toStringAsFixed(1)}%'
                      : '0%',
                  history: _cpuHistory,
                  lineColor: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                _buildMetricCard(
                  title: 'Memória RAM',
                  subtitle: _memHistory.isNotEmpty
                      ? '${_memHistory.last.y.toStringAsFixed(1)}%'
                      : '0%',
                  history: _memHistory,
                  lineColor: Colors.purple,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Constrói o Card com o Gráfico de Linha em tempo real (Estilo Windows 11)
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
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: lineColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY:
                      100, // Escala fixa de 0 a 100% igual ao monitor do Windows
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine:
                        false, // Linhas horizontais de grade limpas
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).dividerColor.withOpacity(0.1),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: const FlTitlesData(
                    show: false,
                  ), // Remove bordas de texto para visual minimalista
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: history,
                      isCurved: true, // Curva suave na linha do gráfico
                      barWidth: 2,
                      color: lineColor,
                      dotData: const FlDotData(
                        show: false,
                      ), // Oculta bolinhas nos nós
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
} // Chave final que fecha a classe corretamente
