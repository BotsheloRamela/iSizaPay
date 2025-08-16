import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isiza_pay/domain/enums/payment_request_status.dart';
import 'package:isiza_pay/presentation/screens/p2p_discovery_screen.dart';
import 'package:provider/provider.dart' as provider;
import 'services/p2p_service.dart';
import 'services/payment_service.dart';
import 'presentation/widgets/error_dialog.dart';
import 'presentation/screens/payment_send_screen.dart';
import 'presentation/screens/payment_receive_screen.dart';
import 'presentation/screens/transaction_history_screen.dart';
import 'package:isiza_pay/core/di/providers.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(create: (context) => P2PService()),
        provider.ChangeNotifierProvider(create: (context) => PaymentService()),
      ],
      child: provider.Consumer2<P2PService, PaymentService>(
        builder: (context, p2pService, paymentService, child) {
          // Set up message handling between P2P and Payment services
          p2pService.onMessageReceived = (endpointId, message) {
            paymentService.handleIncomingMessage(message);
          };
          
          return MaterialApp(
            title: 'Isiza Pay - P2P',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
              useMaterial3: true,
            ),
            home: const MyHomePage(title: 'Isiza Pay'),
          );
        },
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TransactionHistoryScreen(),
                ),
              );
            },
            tooltip: 'Transaction History',
          ),
        ],
      ),
      body: provider.Consumer2<P2PService, PaymentService>(
        builder: (context, p2pService, paymentService, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildBalanceCard(paymentService),
                const SizedBox(height: 20),
                _buildConnectionStatus(p2pService),
                const SizedBox(height: 20),
                _buildPaymentActions(p2pService),
                const SizedBox(height: 20),
                _buildP2PActions(context, p2pService),
                const SizedBox(height: 20),
                _buildIncomingRequests(paymentService),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(PaymentService paymentService) {
    return Consumer(
      builder: (context, ref, child) {
        final blockchainState = ref.watch(blockchainViewModelProvider);
        
        return Card(
          color: Colors.green.shade50,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 48,
                  color: Colors.green.shade600,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your Balance',
                  style: TextStyle(
                    color: Colors.green.shade800,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (blockchainState.isLoading)
                  const CircularProgressIndicator()
                else
                  Text(
                    '\$${blockchainState.balance.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green.shade900,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (blockchainState.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Error: ${blockchainState.error}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConnectionStatus(P2PService p2pService) {
    if (p2pService.connectedDevices.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Connect to nearby devices to send and receive payments',
                style: TextStyle(color: Colors.orange.shade800),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.link, color: Colors.green.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${p2pService.connectedDevices.length} device(s) connected',
              style: TextStyle(
                color: Colors.green.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentActions(P2PService p2pService) {
    final hasConnectedDevices = p2pService.connectedDevices.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payments, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Payment Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: hasConnectedDevices
                        ? () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const PaymentSendScreen(),
                              ),
                            );
                          }
                        : null,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Payment'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const PaymentReceiveScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.request_quote),
                    label: const Text('Receive'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildP2PActions(BuildContext context, P2PService p2pService) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.wifi_tethering, color: Colors.purple.shade600),
                const SizedBox(width: 8),
                Text(
                  'Network Connection',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.purple.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final permissionStatus = await p2pService.checkPermissionStatus();
                  final allGranted = permissionStatus.values.every((granted) => granted);
                  
                  bool shouldNavigate = true;
                  
                  if (!allGranted && context.mounted) {
                    shouldNavigate = await PermissionGuideDialog.show(context);
                  }
                  
                  if (shouldNavigate && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const P2PDiscoveryScreen(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.search),
                label: const Text('Connect to Devices'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomingRequests(PaymentService paymentService) {
    final incomingRequests = paymentService.incomingRequests
        .where((request) => request.status == PaymentRequestStatus.pending)
        .toList();

    if (incomingRequests.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Text(
                  'Incoming Payment Requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${incomingRequests.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'You have ${incomingRequests.length} pending payment request(s)',
              style: TextStyle(color: Colors.red.shade700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const PaymentReceiveScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View Requests'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
