import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isiza_pay/domain/entities/event_product.dart';
import 'package:isiza_pay/domain/entities/event_transaction.dart';
import 'package:isiza_pay/domain/entities/vendor_info.dart';
import 'package:isiza_pay/domain/repositories/event_mode_repository.dart';
import 'package:isiza_pay/domain/usecases/start_event_mode_usecase.dart';
import 'package:isiza_pay/domain/usecases/discover_vendors_usecase.dart';
import 'package:isiza_pay/domain/usecases/purchase_item_usecase.dart';
import 'package:isiza_pay/data/repositories/event_mode_repository_impl.dart';

// State class for Event Mode
class EventModeState {
  final bool isEventModeActive;
  final List<VendorInfoEntity> discoveredVendors;
  final List<EventProductEntity> vendorProducts;
  final List<EventTransactionEntity> transactions;
  final bool isLoading;
  final String? error;
  final String? currentVendorId;
  final String? currentCustomerId;

  const EventModeState({
    this.isEventModeActive = false,
    this.discoveredVendors = const [],
    this.vendorProducts = const [],
    this.transactions = const [],
    this.isLoading = false,
    this.error,
    this.currentVendorId,
    this.currentCustomerId,
  });

  EventModeState copyWith({
    bool? isEventModeActive,
    List<VendorInfoEntity>? discoveredVendors,
    List<EventProductEntity>? vendorProducts,
    List<EventTransactionEntity>? transactions,
    bool? isLoading,
    String? error,
    String? currentVendorId,
    String? currentCustomerId,
  }) {
    return EventModeState(
      isEventModeActive: isEventModeActive ?? this.isEventModeActive,
      discoveredVendors: discoveredVendors ?? this.discoveredVendors,
      vendorProducts: vendorProducts ?? this.vendorProducts,
      transactions: transactions ?? this.transactions,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      currentVendorId: currentVendorId ?? this.currentVendorId,
      currentCustomerId: currentCustomerId ?? this.currentCustomerId,
    );
  }
}

// Notifier class for Event Mode
class EventModeNotifier extends StateNotifier<EventModeState> {
  final StartEventModeUseCase _startEventModeUseCase;
  final DiscoverVendorsUseCase _discoverVendorsUseCase;
  final PurchaseItemUseCase _purchaseItemUseCase;
  final EventModeRepository _repository;

  EventModeNotifier(
    this._startEventModeUseCase,
    this._discoverVendorsUseCase,
    this._purchaseItemUseCase,
    this._repository,
  ) : super(const EventModeState());

  // Start Event Mode (Vendor)
  Future<void> startEventMode({
    required String vendorId,
    required String vendorName,
    required String description,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _startEventModeUseCase.execute(
        vendorId: vendorId,
        vendorName: vendorName,
        description: description,
      );
      
      state = state.copyWith(
        isEventModeActive: true,
        currentVendorId: vendorId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // Stop Event Mode (Vendor)
  Future<void> stopEventMode() async {
    if (state.currentVendorId == null) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _repository.stopEventMode(state.currentVendorId!);
      
      state = state.copyWith(
        isEventModeActive: false,
        currentVendorId: null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // Discover Vendors (Customer)
  Future<void> discoverVendors() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final vendors = await _discoverVendorsUseCase.execute();
      
      state = state.copyWith(
        discoveredVendors: vendors,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // Purchase Item (Customer)
  Future<void> purchaseItem({
    required String customerId,
    required String vendorId,
    required List<EventProductEntity> products,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final transaction = await _purchaseItemUseCase.execute(
        customerId: customerId,
        vendorId: vendorId,
        products: products,
      );
      
      final updatedTransactions = [...state.transactions, transaction];
      
      state = state.copyWith(
        transactions: updatedTransactions,
        currentCustomerId: customerId,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Set current customer
  void setCurrentCustomer(String customerId) {
    state = state.copyWith(currentCustomerId: customerId);
  }
}

// Provider definitions
final eventModeRepositoryProvider = Provider<EventModeRepository>((ref) {
  return EventModeRepositoryImpl();
});

final startEventModeUseCaseProvider = Provider<StartEventModeUseCase>((ref) {
  final repository = ref.watch(eventModeRepositoryProvider);
  return StartEventModeUseCase(repository);
});

final discoverVendorsUseCaseProvider = Provider<DiscoverVendorsUseCase>((ref) {
  final repository = ref.watch(eventModeRepositoryProvider);
  return DiscoverVendorsUseCase(repository);
});

final purchaseItemUseCaseProvider = Provider<PurchaseItemUseCase>((ref) {
  final repository = ref.watch(eventModeRepositoryProvider);
  return PurchaseItemUseCase(repository);
});

final eventModeProvider = StateNotifierProvider<EventModeNotifier, EventModeState>((ref) {
  final startEventModeUseCase = ref.watch(startEventModeUseCaseProvider);
  final discoverVendorsUseCase = ref.watch(discoverVendorsUseCaseProvider);
  final purchaseItemUseCase = ref.watch(purchaseItemUseCaseProvider);
  final repository = ref.watch(eventModeRepositoryProvider);
  
  return EventModeNotifier(
    startEventModeUseCase,
    discoverVendorsUseCase,
    purchaseItemUseCase,
    repository,
  );
});
