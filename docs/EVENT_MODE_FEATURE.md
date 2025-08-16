# Event Mode Feature Documentation

## Overview
The Event Mode feature enables offline peer-to-peer blockchain payments between vendors and customers at events, festivals, or any offline gathering. Vendors can activate a "beacon mode" that makes them discoverable to nearby customers, who can then browse products and make instant payments.

## Architecture

### Domain Layer
- **Entities**: `EventProductEntity`, `EventTransactionEntity`, `VendorInfoEntity`
- **Repository Interface**: `EventModeRepository`
- **Use Cases**: `StartEventModeUseCase`, `DiscoverVendorsUseCase`, `PurchaseItemUseCase`

### Data Layer
- **Repository Implementation**: `EventModeRepositoryImpl` (using SharedPreferences for local storage)
- **Data Models**: JSON serialization/deserialization for local storage

### Presentation Layer
- **State Management**: Riverpod providers with `EventModeState` and `EventModeNotifier`
- **Screens**: `VendorEventModeScreen`, `CustomerDiscoveryScreen`
- **UI Components**: Responsive cards, forms, and lists

## Key Features

### Vendor Side
1. **Start/Stop Event Mode**: Toggle beacon mode on/off
2. **Product Management**: Add, edit, and remove products
3. **Transaction Monitoring**: View customer purchases and transaction history
4. **Connection Management**: Handle multiple customer connections

### Customer Side
1. **Vendor Discovery**: Find nearby vendors in Event Mode
2. **Product Browsing**: View available products and prices
3. **Instant Purchases**: Make quick payments with simple interactions
4. **Transaction History**: Track all Event Mode purchases

## Technical Implementation

### State Management
- Uses Riverpod for reactive state management
- Centralized state in `EventModeProvider`
- Proper error handling and loading states

### Local Storage
- SharedPreferences for persistent local storage
- JSON serialization for complex objects
- Efficient data retrieval and updates

### Offline-First Design
- All operations work without internet connectivity
- Local transaction queuing
- Synchronization ready for future implementation

## Usage Examples

### Starting Event Mode (Vendor)
```dart
final eventModeNotifier = ref.read(eventModeProvider.notifier);
await eventModeNotifier.startEventMode(
  vendorId: 'vendor_123',
  vendorName: 'Food Truck',
  description: 'Delicious street food',
);
```

### Discovering Vendors (Customer)
```dart
final eventModeNotifier = ref.read(eventModeProvider.notifier);
await eventModeNotifier.discoverVendors();
```

### Making a Purchase (Customer)
```dart
final eventModeNotifier = ref.read(eventModeProvider.notifier);
await eventModeNotifier.purchaseItem(
  customerId: 'customer_456',
  vendorId: 'vendor_123',
  products: [product1, product2],
);
```

## Future Enhancements

1. **Real P2P Connectivity**: WiFi Direct, Bluetooth, or NFC implementation
2. **Blockchain Integration**: Connect to existing blockchain infrastructure
3. **Data Synchronization**: Sync transactions when online
4. **Advanced Discovery**: Location-based vendor filtering
5. **Payment Methods**: Support for multiple payment types

## Dependencies

- `flutter_riverpod`: State management
- `shared_preferences`: Local storage
- `flutter`: UI framework

## Testing

The feature includes:
- Proper error handling and validation
- Loading states and user feedback
- Responsive UI components
- Clean separation of concerns

## Security Considerations

- Local transaction storage
- Input validation on all forms
- Secure transaction ID generation
- Proper error handling without exposing sensitive data

## Performance

- Efficient local storage operations
- Minimal memory usage
- Responsive UI updates
- Optimized for battery usage during beacon mode
