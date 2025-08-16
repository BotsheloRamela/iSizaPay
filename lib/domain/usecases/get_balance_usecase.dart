import 'package:isiza_pay/domain/repositories/blockchain.dart';

class GetBalanceUseCase {
  final BlockchainRepository _repository;

  GetBalanceUseCase(this._repository);

  Future<double> execute(String publicKey) async {
    return await _repository.getBalance(publicKey);
  }
}