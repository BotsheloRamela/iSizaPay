import 'package:isiza_pay/domain/entities/transaction.dart';
import 'package:isiza_pay/domain/repositories/blockchain.dart';

class GetTransactionHistoryUseCase {
  final BlockchainRepository _repository;

  GetTransactionHistoryUseCase(this._repository);

  Future<List<TransactionEntity>> execute({String? publicKey}) async {
    final allTransactions = await _repository.getTransactionHistory();
    
    if (publicKey == null) {
      return allTransactions;
    }
    
    return allTransactions.where((transaction) =>
      transaction.senderPublicKey == publicKey ||
      transaction.receiverPublicKey == publicKey
    ).toList();
  }
}