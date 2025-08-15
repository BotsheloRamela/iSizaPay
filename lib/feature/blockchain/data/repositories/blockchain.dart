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
    final txModel = TransactionModel.fromEntity(
      tx,
      hash: tx.hash,
      previousHash: tx.previousHash,
    );
    await localDb.insert(
      'transactions',
      txModel.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    try {
      // Try sending the transaction via Solana RPC
      final signature = await client.sendAndConfirmTransaction(
        tx.message,
      );

      // Mark as pending with signature in local DB
      await localDb.update(
        'transactions',
        {'status': 'pending', 'id': signature},
        where: 'id = ?',
        whereArgs: [txModel.id],
      );

      // Verify on Solscan and update status
      await verifyTransaction(signature);
    } catch (e) {
      // Offline or failed: leave status as pending
      print('Transaction could not be sent: $e');
    }
  }

  @override
  Future<List<TransactionEntity>> getPendingTransactions() async {
    final result = await localDb.query(
      'transactions',
      where: 'status = ?',
      whereArgs: ['pending'],
    );

    return result.map((e) => TransactionModel.fromMap(e).toEntity()).toList();
  }

  @override
  Future<void> syncPendingTransactions() async {
    final txModel = TransactionModel.fromEntity(
          tx,
          hash: tx.hash ?? '',
          previousHash: tx.previousHash ?? '',
    );

    for (var tx in pending) {
      try {
        final txModel = TransactionModel.fromEntity(tx);
        final signature = await client.sendAndConfirmTransaction(
          txModel.toMessage,
        );

        await verifyTransaction(signature);
      } catch (e) {
        print('Failed to sync transaction ${tx.id}: $e');
      }
    }
  }

  @override
  Future<double> getBalance(String walletAddress) async {
    return await client.getBalance(Pubkey.fromBase58(walletAddress));
  }

  @override
  Future<void> verifyTransaction(String txSignature) async {
    final result = await solscan.getTransaction(txSignature);

    final status = (result['status'] == 'Success') ? 'confirmed' : 'pending';

    await localDb.update(
      'transactions',
      {'status': status},
      where: 'id = ?',
      whereArgs: [txSignature],
    );
  }
}
