import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/p2p_service.dart';
import 'screens/p2p_discovery_screen.dart';
import 'widgets/error_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => P2PService(),
      child: MaterialApp(
        title: 'Isiza Pay - P2P',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MyHomePage(title: 'Isiza Pay'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.wifi_tethering,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Peer-to-Peer Network',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Discover and connect to nearby devices',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Consumer<P2PService>(
              builder: (context, service, child) {
                return Column(
                  children: [
                    if (service.connectedDevices.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.symmetric(horizontal: 32),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link, color: Colors.green.shade600),
                            const SizedBox(width: 8),
                            Text(
                              '${service.connectedDevices.length} device(s) connected',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final shouldProceed = await PermissionGuideDialog.show(context);
                        if (shouldProceed && context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const P2PDiscoveryScreen(),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.search),
                      label: const Text('Start P2P Discovery'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
