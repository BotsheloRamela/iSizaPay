import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isiza_pay/presentation/providers/event_mode_provider.dart';
import 'package:isiza_pay/domain/entities/vendor_info.dart';

class CustomerDiscoveryScreen extends ConsumerStatefulWidget {
  const CustomerDiscoveryScreen({super.key});

  @override
  ConsumerState<CustomerDiscoveryScreen> createState() => _CustomerDiscoveryScreenState();
}

class _CustomerDiscoveryScreenState extends ConsumerState<CustomerDiscoveryScreen> {
  @override
  void initState() {
    super.initState();
    // Start discovering vendors when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(eventModeProvider.notifier).discoverVendors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final eventModeState = ref.watch(eventModeProvider);
    final eventModeNotifier = ref.read(eventModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover Vendors'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => eventModeNotifier.discoverVendors(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Search and Filter Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.search, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          'Nearby Vendors',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Discover vendors in Event Mode near you',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Vendors List
            Expanded(
              child: eventModeState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : eventModeState.discoveredVendors.isEmpty
                      ? _buildEmptyState()
                      : _buildVendorsList(eventModeState.discoveredVendors),
            ),

            // Error Display
            if (eventModeState.error != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          eventModeState.error!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                      IconButton(
                        onPressed: () => eventModeNotifier.clearError(),
                        icon: const Icon(Icons.close),
                        color: Colors.red.shade700,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Vendors Found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No vendors are currently in Event Mode nearby.\nTry refreshing or check back later.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref.read(eventModeProvider.notifier).discoverVendors(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorsList(List<VendorInfoEntity> vendors) {
    return ListView.builder(
      itemCount: vendors.length,
      itemBuilder: (context, index) {
        final vendor = vendors[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: Icon(
                Icons.store,
                color: Colors.white,
              ),
            ),
            title: Text(
              vendor.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(vendor.description),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.wifi_tethering,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Event Mode Active',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontSize: 12,
                      ),
                    ),
                    if (vendor.location != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vendor.location!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
                if (vendor.rating != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${vendor.rating!.toStringAsFixed(1)} (${vendor.totalTransactions} transactions)',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () => _connectToVendor(vendor),
              child: const Text('Connect'),
            ),
            onTap: () => _showVendorDetails(vendor),
          ),
        );
      },
    );
  }

  void _connectToVendor(VendorInfoEntity vendor) {
    // TODO: Implement connection logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Connecting to ${vendor.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showVendorDetails(VendorInfoEntity vendor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(
                      Icons.store,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        Text(
                          vendor.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Vendor Details
              _buildDetailRow('Status', 'Event Mode Active', Icons.wifi_tethering, Colors.green),
              if (vendor.location != null)
                _buildDetailRow('Location', vendor.location!, Icons.location_on, Colors.blue),
              if (vendor.rating != null)
                _buildDetailRow('Rating', '${vendor.rating!.toStringAsFixed(1)}/5.0', Icons.star, Colors.amber),
              _buildDetailRow('Transactions', '${vendor.totalTransactions}', Icons.receipt, Colors.grey),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _connectToVendor(vendor);
                  },
                  icon: const Icon(Icons.connect_without_contact),
                  label: const Text('Connect & Browse Products'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
