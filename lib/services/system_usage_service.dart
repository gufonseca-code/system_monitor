import 'dart:async';
import 'dart:io';

/// Estrutura para agrupar as métricas de desempenho coletadas
class SystemMetrics {
  final double cpuUsagePercentage;
  final double totalMemoryGb;
  final double usedMemoryGb;
  final double memoryUsagePercentage;

  SystemMetrics({
    required this.cpuUsagePercentage,
    required this.totalMemoryGb,
    required this.usedMemoryGb,
    required this.memoryUsagePercentage,
  });
}

class SystemUsageService {
  // Variáveis para calcular a diferença de tempo da CPU (Necessário para cálculo de % real)
  int _lastUser = 0;
  int _lastNice = 0;
  int _lastSystem = 0;
  int _lastIdle = 0;

  /// Transforma a leitura periódica do sistema operacional em um Stream contínuo
  Stream<SystemMetrics> get metricsStream async* {
    while (true) {
      await Future.delayed(
        const Duration(seconds: 1),
      ); // Atualização a cada 1 segundo
      yield await _collectMetrics();
    }
  }

  Future<SystemMetrics> _collectMetrics() async {
    final cpu = await _readCpuUsage();
    final mem = await _readMemoryUsage();

    return SystemMetrics(
      cpuUsagePercentage: cpu,
      totalMemoryGb: mem['total'] ?? 0.0,
      usedMemoryGb: mem['used'] ?? 0.0,
      memoryUsagePercentage: mem['percentage'] ?? 0.0,
    );
  }

  /// Faz o parse de /proc/stat para calcular o uso percentual da CPU
  Future<double> _readCpuUsage() async {
    try {
      final file = File('/proc/stat');
      if (!await file.exists()) return 0.0;

      final firstLine = await file.readAsLines().then((lines) => lines.first);
      // Exemplo de linha: cpu  2255 34 2290 2262556 ...
      final parts = firstLine
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();

      if (parts.length < 5) return 0.0;

      int user = int.parse(parts[1]);
      int nice = int.parse(parts[2]);
      int system = int.parse(parts[3]);
      int idle = int.parse(parts[4]);

      // Diferenças entre a leitura atual e a leitura anterior
      int diffUser = user - _lastUser;
      int diffNice = nice - _lastNice;
      int diffSystem = system - _lastSystem;
      int diffIdle = idle - _lastIdle;

      // Salva os estados atuais para o próximo ciclo
      _lastUser = user;
      _lastNice = nice;
      _lastSystem = system;
      _lastIdle = idle;

      int totalAtivo = diffUser + diffNice + diffSystem;
      int totalGeral = totalAtivo + diffIdle;

      if (totalGeral == 0) return 0.0;
      return (totalAtivo / totalGeral) * 100;
    } catch (_) {
      return 0.0;
    }
  }

  /// Faz o parse de /proc/meminfo para extrair o consumo de memória
  Future<Map<String, double>> _readMemoryUsage() async {
    try {
      final file = File('/proc/meminfo');
      if (!await file.exists())
        return {'total': 0.0, 'used': 0.0, 'percentage': 0.0};

      final lines = await file.readAsLines();
      double memTotal = 0.0;
      double memAvailable = 0.0;

      for (var line in lines) {
        if (line.startsWith('MemTotal:')) {
          memTotal = _parseMemValue(line);
        } else if (line.startsWith('MemAvailable:')) {
          memAvailable = _parseMemValue(line);
        }
      }

      // Memória usada no Linux = Total - Disponível
      double memUsed = memTotal - memAvailable;
      double percentage = memTotal > 0 ? (memUsed / memTotal) * 100 : 0.0;

      // Converte de kB para Gigabytes (GB)
      return {
        'total': memTotal / (1024 * 1024),
        'used': memUsed / (1024 * 1024),
        'percentage': percentage,
      };
    } catch (_) {
      return {'total': 0.0, 'used': 0.0, 'percentage': 0.0};
    }
  }

  double _parseMemValue(String line) {
    // Remove o texto e deixa apenas os dígitos numéricos
    final match = RegExp(r'\d+').firstMatch(line);
    if (match != null) {
      return double.parse(match.group(0)!);
    }
    return 0.0;
  }
}
