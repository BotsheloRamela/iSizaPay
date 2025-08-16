import 'package:isiza_pay/domain/entities/block.dart';
import 'package:isiza_pay/domain/entities/transaction.dart';
import 'package:isiza_pay/domain/repositories/blockchain.dart';

class CreateBlockUseCase {
  final BlockchainRepository _repository;

  CreateBlockUseCase(this._repository);

  Future<BlockEntity> execute(List<TransactionEntity> transactions) async {
    final block = await _repository.createBlock(transactions);
    await _repository.addBlock(block);
    return block;
  }
}