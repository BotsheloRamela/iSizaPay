
import 'package:isiza_pay/domain/entities/block.dart';
import 'package:isiza_pay/domain/entities/transaction.dart';

abstract class BlockchainRepository {
  Future<void> addTransaction(TransactionEntity transaction);
  Future<BlockEntity> createBlock(List<TransactionEntity> transactions);
  Future<void> addBlock(BlockEntity block);
  Future<List<TransactionEntity>> getTransactionHistory();
  Future<List<BlockEntity>> getBlockchain();
  Future<bool> validateChain();
  Future<TransactionEntity?> getTransactionById(String id);
  Future<BlockEntity?> getLatestBlock();
  Future<double> getBalance(String publicKey);
}
