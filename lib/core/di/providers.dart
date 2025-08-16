
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

final blockchainViewModelProvider = StateNotifierProvider<BlockchainNotifier, BlockchainState>(
  (ref) => BlockchainNotifier(
    ref.read(createTransactionUseCaseProvider),
    ref.read(validateChainUseCaseProvider),
    ref.read(getTransactionHistoryUseCaseProvider),
    ref.read(getBalanceUseCaseProvider),
    ref.read(createBlockUseCaseProvider),
  ),
);
