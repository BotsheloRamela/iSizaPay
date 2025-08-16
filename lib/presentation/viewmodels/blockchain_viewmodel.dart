import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solana/solana.dart';
import 'package:isiza_pay/domain/entities/block.dart';
import 'package:isiza_pay/domain/entities/transaction.dart';
import 'package:isiza_pay/domain/usecases/create_transaction_usecase.dart';
import 'package:isiza_pay/domain/usecases/validate_chain_usecase.dart';
import 'package:isiza_pay/domain/usecases/get_transaction_history_usecase.dart';
import 'package:isiza_pay/domain/usecases/get_balance_usecase.dart';
import 'package:isiza_pay/domain/usecases/create_block_usecase.dart';

class BlockchainState {
  final List<TransactionEntity> transactions;
  final List<BlockEntity> blocks;
  final bool isChainValid;
  final double balance;
  final bool isLoading;
  final String? error;
  final Ed25519HDKeyPair? keyPair;

  const BlockchainState({
    this.transactions = const [],
    this.blocks = const [],
    this.isChainValid = true,
    this.balance = 0.0,
    this.isLoading = false,
    this.error,
    this.keyPair,
  });

  BlockchainState copyWith({
    List<TransactionEntity>? transactions,
    List<BlockEntity>? blocks,
    bool? isChainValid,
    double? balance,
    bool? isLoading,
    String? error,
    Ed25519HDKeyPair? keyPair,
  }) {
    return BlockchainState(
      transactions: transactions ?? this.transactions,
      blocks: blocks ?? this.blocks,
      isChainValid: isChainValid ?? this.isChainValid,
      balance: balance ?? this.balance,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      keyPair: keyPair ?? this.keyPair,
    );
  }
}

class BlockchainNotifier extends StateNotifier<BlockchainState> {
  final CreateTransactionUseCase _createTransactionUseCase;
  final ValidateChainUseCase _validateChainUseCase;
  final GetTransactionHistoryUseCase _getTransactionHistoryUseCase;
  final GetBalanceUseCase _getBalanceUseCase;
  final CreateBlockUseCase _createBlockUseCase;

  BlockchainNotifier(
    this._createTransactionUseCase,
    this._validateChainUseCase,
    this._getTransactionHistoryUseCase,
    this._getBalanceUseCase,
    this._createBlockUseCase,
  ) : super(const BlockchainState()) {
    _initializeKeyPair();
    _loadData();
  }

  void _initializeKeyPair() async {
    final keyPair = await Ed25519HDKeyPair.random();
    state = state.copyWith(keyPair: keyPair);
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true);
    
    try {
      await Future.wait([
        _loadTransactionHistory(),
        _validateChain(),
        _loadBalance(),
      ]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadTransactionHistory() async {
    final transactions = await _getTransactionHistoryUseCase.execute();
    state = state.copyWith(transactions: transactions);
  }

  Future<void> _validateChain() async {
    final isValid = await _validateChainUseCase.execute();
    state = state.copyWith(isChainValid: isValid);
  }

  Future<void> _loadBalance() async {
    if (state.keyPair != null) {
      final publicKey = state.keyPair!.address;
      final balance = await _getBalanceUseCase.execute(publicKey);
      state = state.copyWith(balance: balance);
    }
  }

  Future<void> createTransaction({
    required String receiverPublicKey,
    required num amount,
  }) async {
    if (state.keyPair == null) {
      state = state.copyWith(error: 'Wallet not initialized');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final transaction = await _createTransactionUseCase.execute(
        senderPublicKey: state.keyPair!.address,
        receiverPublicKey: receiverPublicKey,
        amount: amount,
        senderKeyPair: state.keyPair!,
      );

      await _loadTransactionHistory();
      await _loadBalance();
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create transaction: ${e.toString()}',
      );
    }
  }

  Future<void> createBlock(List<TransactionEntity> transactions) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final block = await _createBlockUseCase.execute(transactions);
      
      final updatedBlocks = [...state.blocks, block];
      state = state.copyWith(blocks: updatedBlocks);
      
      await _validateChain();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to create block: ${e.toString()}',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> refreshData() async {
    await _loadData();
  }

  String get publicKey => state.keyPair?.address ?? '';
}