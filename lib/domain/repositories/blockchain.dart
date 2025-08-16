
import 'package:isiza_pay/domain/entities/transaction.dart';

abstract class BlockchainRepository {
  Future<void> sendTransaction(TransactionEntity tx);
  Future<List<TransactionEntity>> getPendingTransactions();
  Future<void> syncPendingTransactions();
  Future<double> getBalance(String walletAddress);
  Future<void> verifyTransaction(String txSignature);
}
