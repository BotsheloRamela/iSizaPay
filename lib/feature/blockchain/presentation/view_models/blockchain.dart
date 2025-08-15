// lib/features/blockchain/presentation/view_models/blockchain_vm.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/blockchain_repository.dart';

final blockchainVMProvider = StateNotifierProvider<BlockchainVM, List<TransactionEntity>>(
  (ref) => BlockchainVM(ref.read),
);

class BlockchainVM extends StateNotifier<List<TransactionEntity>> {
  final Reader read;
  BlockchainVM(this.read) : super([]);

  Future<void> loadPendingTransactions() async {
    final repo = read(blockchainRepositoryProvider);
    state = await repo.getPendingTransactions();
  }

  Future<void> sendTransaction(TransactionEntity tx) async {
    final repo = read(blockchainRepositoryProvider);
    await repo.sendTransaction(tx);
    await loadPendingTransactions();
  }

  Future<void> syncTransactions() async {
    final repo = read(blockchainRepositoryProvider);
    await repo.syncPendingTransactions();
    await loadPendingTransactions();
  }

  Future<void> verifyTransaction(String txSignature) async {
    (ref) => BlockchainVM(ref),
    await repo.verifyTransaction(txSignature);
    await loadPendingTransactions();
  }
}
