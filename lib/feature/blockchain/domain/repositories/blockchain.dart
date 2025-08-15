// lib/features/blockchain/domain/repositories/blockchain_repository.dart
import '../entities/transaction_entity.dart';

abstract class BlockchainRepository {
  Future<void> sendTransaction(TransactionEntity tx);
  Future<List<TransactionEntity>> getPendingTransactions();
  Future<void> syncPendingTransactions();
  Future<double> getBalance(String walletAddress);
  Future<void> verifyTransaction(String txSignature);
}
