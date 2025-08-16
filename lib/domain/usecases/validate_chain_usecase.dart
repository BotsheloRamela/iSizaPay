import 'package:isiza_pay/domain/repositories/blockchain.dart';

class ValidateChainUseCase {
  final BlockchainRepository _repository;

  ValidateChainUseCase(this._repository);

  Future<bool> execute() async {
    return await _repository.validateChain();
  }
}