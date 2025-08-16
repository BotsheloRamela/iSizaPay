import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isiza_pay/presentation/providers/event_mode_provider.dart';
import 'package:isiza_pay/domain/entities/event_product.dart';

class VendorEventModeScreen extends ConsumerStatefulWidget {
  const VendorEventModeScreen({super.key});

  @override
  ConsumerState<VendorEventModeScreen> createState() => _VendorEventModeScreenState();
}

class _VendorEventModeScreenState extends ConsumerState<VendorEventModeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _productNameController = TextEditingController();
  final _productPriceController = TextEditingController();
  final _productDescriptionController = TextEditingController();

  @override
  void dispose() {
    _vendorNameController.dispose();
    _descriptionController.dispose();
    _productNameController.dispose();
    _productPriceController.dispose();
    _productDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventModeState = ref.watch(eventModeProvider);
    final eventModeNotifier = ref.read(eventModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Mode Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event Mode Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          eventModeState.isEventModeActive
                              ? Icons.wifi_tethering
                              : Icons.wifi_tethering_off,
                          color: eventModeState.isEventModeActive
                              ? Colors.green
                              : Colors.grey,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event Mode Status',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                eventModeState.isEventModeActive
                                    ? 'Active - Customers can discover you'
                                    : 'Inactive - Start to accept payments',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!eventModeState.isEventModeActive)
                      ElevatedButton.icon(
                        onPressed: eventModeState.isLoading
                            ? null
                            : () => _showStartEventModeDialog(context, eventModeNotifier),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Event Mode'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: eventModeState.isLoading
                            ? null
                            : () => eventModeNotifier.stopEventMode(),
                        icon: const Icon(Icons.stop),
                        label: const Text('Stop Event Mode'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Product Management Section
            if (eventModeState.isEventModeActive) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.inventory, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Product Catalog',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddProductDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Products List
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Products',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: eventModeState.vendorProducts.isEmpty
                              ? const Center(
                                  child: Text('No products added yet'),
                                )
                              : ListView.builder(
                                  itemCount: eventModeState.vendorProducts.length,
                                  itemBuilder: (context, index) {
                                    final product = eventModeState.vendorProducts[index];
                                    return ListTile(
                                      title: Text(product.name),
                                      subtitle: Text(product.description),
                                      trailing: Text(
                                        '\$${product.price.toStringAsFixed(2)}',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],

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

            // Loading Indicator
            if (eventModeState.isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  void _showStartEventModeDialog(BuildContext context, EventModeNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Event Mode'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _vendorNameController,
                decoration: const InputDecoration(
                  labelText: 'Vendor Name',
                  hintText: 'Enter your business name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a vendor name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief description of your business',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                notifier.startEventMode(
                  vendorId: 'vendor_${DateTime.now().millisecondsSinceEpoch}',
                  vendorName: _vendorNameController.text,
                  description: _descriptionController.text,
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Product'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  hintText: 'Enter product name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productPriceController,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  hintText: 'Enter price',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter product description',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // TODO: Implement add product functionality
                Navigator.of(context).pop();
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
