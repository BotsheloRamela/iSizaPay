// lib/features/blockchain/data/repositories/blockchain_repository_impl.dart
import 'package:solana/solana.dart';
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/blockchain_repository.dart';
import '../solscan/solscan_service.dart';
import '../models/transaction_model.dart';

class BlockchainRepositoryImpl implements BlockchainRepository {
  final RpcClient client;
  final Database localDb;
  final SolscanService solscan;

  BlockchainRepositoryImpl({
    required this.client,
    required this.localDb,
    required this.solscan,
  });

  @override
  Future<void> sendTransaction(TransactionEntity tx) async {
    // Save locally first (offline)
    await localDb.insert('transactions', TransactionModel.fromEntity(tx).toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);

    // If online, push to Solana
    // Example:
    // final signature = await client.sendTransaction(...);
    // await verifyTransaction(signature);
  }

  @override
  Future<List<TransactionEntity>> getPendingTransactions() async {
    final result = await localDb.query('transactions', where: 'status = ?', whereArgs: ['pending']);
    return result.map((e) => TransactionModel.fromMap(e)).toList();
  }

  @override
  Future<void> syncPendingTransactions() async {
    final pending = await getPendingTransactions();
    for (var tx in pending) {
      // send to Solana if online
      // await client.sendTransaction(...);
      // then verify
      // await verifyTransaction(signature);
    }
  }

  @override
  Future<double> getBalance(String walletAddress) async {
    return await client.getBalance(walletAddress);
  }

  @override
  Future<void> verifyTransaction(String txSignature) async {
    final result = await solscan.getTransaction(txSignature);
    // Update local DB with status
    final status = (result['status'] == 'Success') ? 'confirmed' : 'pending';
    await localDb.update(
      'transactions',
      {'status': status},
      where: 'id = ?',
      whereArgs: [txSignature],
    );
  }
}
