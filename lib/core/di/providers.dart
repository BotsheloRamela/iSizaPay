
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isiza_pay/data/repositories/blockchain_repository_impl.dart';
import 'package:isiza_pay/data/database/blockchain_database.dart';
import 'package:isiza_pay/domain/repositories/blockchain.dart';
import 'package:isiza_pay/domain/usecases/create_transaction_usecase.dart';
import 'package:isiza_pay/domain/usecases/validate_chain_usecase.dart';
import 'package:isiza_pay/domain/usecases/get_transaction_history_usecase.dart';
import 'package:isiza_pay/domain/usecases/get_balance_usecase.dart';
import 'package:isiza_pay/domain/usecases/create_block_usecase.dart';
import 'package:isiza_pay/presentation/viewmodels/blockchain_viewmodel.dart';
import 'package:isiza_pay/services/p2p_service.dart';
import 'package:isiza_pay/services/payment_service.dart';

final blockchainDatabaseProvider = Provider((ref) => BlockchainDatabase());

final blockchainRepositoryProvider = Provider<BlockchainRepository>(
  (ref) => BlockchainRepositoryImpl(ref.read(blockchainDatabaseProvider)),
);

final createTransactionUseCaseProvider = Provider(
  (ref) => CreateTransactionUseCase(ref.read(blockchainRepositoryProvider)),
);

final validateChainUseCaseProvider = Provider(
  (ref) => ValidateChainUseCase(ref.read(blockchainRepositoryProvider)),
);

final getTransactionHistoryUseCaseProvider = Provider(
  (ref) => GetTransactionHistoryUseCase(ref.read(blockchainRepositoryProvider)),
);

final getBalanceUseCaseProvider = Provider(
  (ref) => GetBalanceUseCase(ref.read(blockchainRepositoryProvider)),
);

final createBlockUseCaseProvider = Provider(
  (ref) => CreateBlockUseCase(ref.read(blockchainRepositoryProvider)),
);

// P2P Service Provider
final p2pServiceProvider = ChangeNotifierProvider<P2PService>((ref) {
  return P2PService();
});

// Payment Service Provider  
final paymentServiceProvider = ChangeNotifierProvider<PaymentService>((ref) {
  final paymentService = PaymentService();
  
  // Initialize P2P service reference for sending messages
  final p2pService = ref.read(p2pServiceProvider.notifier);
  paymentService.setP2PService(p2pService);
  
  // Initialize blockchain repository reference for persistent storage
  final blockchainRepository = ref.read(blockchainRepositoryProvider);
  paymentService.setBlockchainRepository(blockchainRepository);
  
  // Set up message handling for payment messages
  p2pService.onMessageReceived = (String endpointId, Map<String, dynamic> message) {
    paymentService.handleIncomingMessage(message);
  };
  
  return paymentService;
});

final blockchainViewModelProvider = StateNotifierProvider<BlockchainNotifier, BlockchainState>(
  (ref) => BlockchainNotifier(
    ref.read(createTransactionUseCaseProvider),
    ref.read(validateChainUseCaseProvider),
    ref.read(getTransactionHistoryUseCaseProvider),
    ref.read(getBalanceUseCaseProvider),
    ref.read(createBlockUseCaseProvider),
  ),
);
