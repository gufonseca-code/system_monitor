import 'package:flutter/material.dart';
import 'package:yaru/yaru.dart';

Future<void> main() async {
  await YaruWindowTitleBar.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SystemMonitorApp());
}

class SystemMonitorApp extends StatelessWidget {
  const SystemMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return YaruTheme(
      builder: (context, yaru, child) {
        return MaterialApp(
          title: 'Monitor de Sistema',
          theme: yaru.theme,
          darkTheme: yaru.darkTheme,
          themeMode: yaru.themeMode,
          debugShowCheckedModeBanner: false,
          home: const HomePage(),
        );
      },
    );
  }
}


class _Page {
  const _Page({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;
}

const _systemPages = [
  _Page(title: 'Desempenho', icon: YaruIcons.computer),
  _Page(title: 'Processos',  icon: YaruIcons.tree),
  _Page(title: 'Histórico',  icon: YaruIcons.history),
];

const _hardwarePages = [
  _Page(title: 'GPU',   icon: YaruIcons.chip),
  _Page(title: 'Disco', icon: YaruIcons.drive_harddisk),
  _Page(title: 'Rede',  icon: YaruIcons.network),
];

const _roboticsPages = [
  _Page(title: 'Serial / USB', icon: YaruIcons.usb_stick),
  _Page(title: 'ROS2',         icon: YaruIcons.game_controller),
  _Page(title: 'Sensores',     icon: YaruIcons.weather),
];

final _allPages = [
  ..._systemPages,
  ..._hardwarePages,
  ..._roboticsPages,
];


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YaruMasterDetailPage(
        length: _allPages.length,
        appBar: YaruWindowTitleBar(
          border: BorderSide.none,
          backgroundColor: YaruMasterDetailTheme.of(context).sideBarColor,
        ),
        tileBuilder: (context, index, selected, availableWidth) {
          return _NavTile(
            page: _allPages[index],
            selected: selected,
            sectionLabel: switch (index) {
              0 => 'Sistema',
              3 => 'Hardware',
              6 => 'Robótica',
              _ => null,
            },
          );
        },
        pageBuilder: (context, index) {
          return _PlaceholderPage(page: _allPages[index]);
        },
      ),
    );
  }
}


class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.page,
    required this.selected,
    this.sectionLabel,
  });

  final _Page page;
  final bool selected;
  final String? sectionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (sectionLabel != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              sectionLabel!.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
        YaruMasterTile(
          leading: Icon(page.icon),
          title: Text(page.title),
        ),
      ],
    );
  }
}

class _PlaceholderPage extends StatelessWidget {
  const _PlaceholderPage({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    return YaruDetailPage(
      appBar: YaruWindowTitleBar(
        title: Text(page.title),
        border: BorderSide.none,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              page.icon,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              page.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Em construção',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}