# Isiza Pay App Architecture 🏗️

Hey there! Let's break down how our Isiza Pay app is built. We've kept things organized and scalable using some solid architectural patterns. Don't worry - we'll keep it simple and explain why we chose what we chose.

## The Big Picture

Our app follows **Clean Architecture** principles with **MVVM** (Model-View-ViewModel) pattern, all tied together with **Riverpod** for state management. Think of it like a well-organized house where everyone knows their role.

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  (UI Screens, Widgets, ViewModels)                         │
├─────────────────────────────────────────────────────────────┤
│                    Domain Layer                             │
│  (Business Logic, Use Cases, Entities)                     │
├─────────────────────────────────────────────────────────────┤
│                    Data Layer                               │
│  (Repositories, Database, External APIs)                   │
└─────────────────────────────────────────────────────────────┘
```

## Why This Architecture?

**Clean Architecture** gives us:
- **Separation of concerns** - each layer has one job
- **Testability** - we can test business logic without UI
- **Maintainability** - changes in one layer don't break others
- **Scalability** - easy to add new features

**MVVM Pattern** gives us:
- **Clear data flow** - View ↔ ViewModel ↔ Model
- **Reactive UI** - UI updates automatically when data changes
- **Business logic separation** - ViewModels handle the heavy lifting

**Riverpod** gives us:
- **Dependency injection** - easy to manage and test dependencies
- **State management** - reactive state that rebuilds UI efficiently
- **Provider pattern** - clean way to share data across the app

## Layer Breakdown

### 🎨 Presentation Layer (`lib/presentation/`)

This is what users see and interact with.

**Screens** (`screens/`):
- `payment_send_screen.dart` - Send money to friends
- `payment_receive_screen.dart` - Request/receive payments
- `transaction_history_screen.dart` - View transaction history
- `p2p_discovery_screen.dart` - Connect to nearby devices

**ViewModels** (`viewmodels/`):
- `blockchain_viewmodel.dart` - Manages blockchain state (balance, transactions, etc.)

**Widgets** (`widgets/`):
- `error_dialog.dart` - Shows error messages nicely

### 🧠 Domain Layer (`lib/domain/`)

The brain of our app - pure business logic with no external dependencies.

**Entities** (`entities/`):
- `transaction.dart` - What a transaction looks like
- `block.dart` - Blockchain block structure
- `payment_request.dart` - Payment request between users

**Use Cases** (`usecases/`):
- `create_transaction_usecase.dart` - Logic for creating transactions
- `get_balance_usecase.dart` - Logic for calculating balance
- `validate_chain_usecase.dart` - Logic for blockchain validation
- And more...

**Repositories** (`repositories/`):
- `blockchain.dart` - Interface defining what blockchain operations we need

**Enums** (`enums/`):
- `transaction_status.dart` - Transaction states (pending, completed, failed)
- `payment_request_status.dart` - Payment request states

### 💾 Data Layer (`lib/data/`)

Handles all data operations - database, external APIs, etc.

**Repositories** (`repositories/`):
- `blockchain_repository_impl.dart` - Actual implementation of blockchain operations

**Database** (`database/`):
- `blockchain_database.dart` - SQLite database for storing blockchain data

**Models** (`models/`):
- `transaction.dart` - Database representation of transactions

**External Services** (`solscan/`):
- `solscan_service.dart` - Integration with Solana blockchain explorer

### 🔧 Services (`lib/services/`)

Cross-cutting services that help different parts of the app work together.

- `p2p_service.dart` - Handles peer-to-peer connections between devices
- `payment_service.dart` - Manages payment flow and requests
- `blockchain_sync_service.dart` - Keeps local blockchain in sync

### 🔌 Dependency Injection (`lib/core/di/`)

**Providers** (`providers.dart`):
All our Riverpod providers live here. Think of this as our "wiring center" where we:
- Create instances of services, repositories, and use cases
- Set up dependencies between them
- Make everything available to the UI

## How Riverpod Ties It All Together

Riverpod is our glue. Here's how it works:

1. **Providers create instances** - We define providers for all our services
2. **Dependency injection** - Providers automatically inject dependencies
3. **State management** - ViewModels extend `StateNotifier` for reactive state
4. **UI consumption** - Widgets use `Consumer` to watch state changes

Example from our code:
```dart
// In providers.dart - we create the provider
final blockchainViewModelProvider = StateNotifierProvider<BlockchainNotifier, BlockchainState>(
  (ref) => BlockchainNotifier(
    ref.read(createTransactionUseCaseProvider),
    ref.read(validateChainUseCaseProvider),
    // ... other dependencies
  ),
);

// In UI - we consume the state
final blockchainState = ref.watch(blockchainViewModelProvider);
```

## Data Flow Example: Sending a Payment

Let's trace how sending a payment works:

1. **User taps "Send Payment"** → `PaymentSendScreen`
2. **Screen calls ViewModel** → `BlockchainNotifier.createTransaction()`
3. **ViewModel uses Use Case** → `CreateTransactionUseCase.execute()`
4. **Use Case calls Repository** → `BlockchainRepository.addTransaction()`
5. **Repository saves to Database** → `BlockchainDatabase`
6. **State updates** → UI automatically rebuilds with new balance
7. **P2P notification** → `PaymentService` notifies connected devices

## Why These Technology Choices?

**Flutter + Dart**: 
- Cross-platform (iOS/Android) with single codebase
- Great performance and smooth animations
- Strong typing helps catch errors early

**Riverpod over Provider/BLoC**:
- More type-safe and compile-time safe
- Better testing support
- Cleaner dependency injection
- Automatic disposal of resources

**SQLite for local storage**:
- Reliable offline-first approach
- Good performance for blockchain data
- Easy to backup and sync

**Solana integration**:
- Fast and cheap transactions
- Good mobile SDK support
- Growing ecosystem

## Testing Strategy

Our architecture makes testing easy:

- **Unit tests** for Use Cases (pure business logic)
- **Widget tests** for UI components
- **Integration tests** for full user flows
- **Repository tests** with mock databases

The clean separation means we can test each layer independently.

## Adding New Features

Want to add a feature? Here's the flow:

1. **Domain first** - Define entities, use cases
2. **Data layer** - Implement repository methods
3. **Presentation** - Create ViewModels and UI
4. **Wire it up** - Add Riverpod providers

This keeps things organized and ensures we don't skip important steps.

## Key Benefits of Our Architecture

✅ **Maintainable** - Clear structure makes changes easy  
✅ **Testable** - Each layer can be tested independently  
✅ **Scalable** - Easy to add features without breaking existing code  
✅ **Readable** - New developers can understand the codebase quickly  
✅ **Reliable** - Less bugs due to separation of concerns  

That's our architecture in a nutshell! It might seem like a lot of structure for a payment app, but this foundation lets us move fast and break fewer things. Plus, as we add more features (multi-currency support, advanced P2P features, etc.), this architecture will keep us organized and productive.