import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:solana/solana.dart';
import 'package:isiza_pay/domain/entities/transaction.dart';
import 'package:isiza_pay/domain/enums/transaction_status.dart';
import 'package:isiza_pay/domain/repositories/blockchain.dart';

class CreateTransactionUseCase {
  final BlockchainRepository _repository;

  CreateTransactionUseCase(this._repository);

  Future<TransactionEntity> execute({
    required String senderPublicKey,
    required String receiverPublicKey,
    required num amount,
    required Ed25519HDKeyPair senderKeyPair,
  }) async {
    final latestBlock = await _repository.getLatestBlock();
    final previousBlockHash = latestBlock?.hash ?? '0';
    
    final transactionData = {
      'senderPublicKey': senderPublicKey,
      'receiverPublicKey': receiverPublicKey,
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
      'previousBlockHash': previousBlockHash,
    };

    final transactionHash = _generateTransactionHash(transactionData);
    final signature = await _signTransaction(transactionHash, senderKeyPair);

    final transaction = TransactionEntity(
      id: transactionHash,
      senderPublicKey: senderPublicKey,
      receiverPublicKey: receiverPublicKey,
      amount: amount,
      timestamp: DateTime.now(),
      signature: signature,
      previousBlockHash: previousBlockHash,
      status: TransactionStatus.pendingOffline,
    );

    await _repository.addTransaction(transaction);
    return transaction;
  }

  String _generateTransactionHash(Map<String, dynamic> transactionData) {
    final input = jsonEncode(transactionData);
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<String> _signTransaction(String transactionHash, Ed25519HDKeyPair keyPair) async {
    final messageBytes = utf8.encode(transactionHash);
    final signature = await keyPair.sign(messageBytes);
    return base64Encode(signature.bytes);
  }
}