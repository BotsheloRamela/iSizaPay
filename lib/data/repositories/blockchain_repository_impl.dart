import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:isiza_pay/domain/entities/block.dart';
import 'package:isiza_pay/domain/entities/transaction.dart';
import 'package:isiza_pay/domain/repositories/blockchain.dart';
import 'package:isiza_pay/data/database/blockchain_database.dart';
import 'package:isiza_pay/core/utils/logger.dart';

class BlockchainRepositoryImpl implements BlockchainRepository {
  final BlockchainDatabase _database;

  BlockchainRepositoryImpl(this._database);

  @override
  Future<void> addTransaction(TransactionEntity transaction) async {
    try {
      final db = await _database.database;
      AppLogger.d('Adding transaction to DB', 'db:transaction:add ${transaction.toJson()}');
      await db.insert(
        'transactions',
        transaction.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      AppLogger.e('Error adding transaction', e.toString());
      throw Exception('Failed to add transaction');
    }
  }

  @override
  Future<BlockEntity> createBlock(List<TransactionEntity> transactions) async {
    try {
      final latestBlock = await getLatestBlock();
      final previousHash = latestBlock?.hash ?? '0';
      final timestamp = DateTime.now();
      final transactionIds = transactions.map((tx) => tx.id).toList();
      final merkleRoot = _calculateMerkleRoot(transactionIds);

      final blockData = {
        'previousHash': previousHash,
        'timestamp': timestamp.toIso8601String(),
        'transactionIds': transactionIds,
        'merkleRoot': merkleRoot,
      };

      int nonce = 0;
      String hash = '';

      do {
        blockData['nonce'] = nonce;
        hash = _calculateHash(blockData);
        nonce++;
      } while (!hash.startsWith('0000'));

      return BlockEntity(
        hash: hash,
        previousHash: previousHash,
        timestamp: timestamp,
        transactionIds: transactionIds,
        nonce: nonce - 1,
        merkleRoot: merkleRoot,
      );
    } catch (e) {
      AppLogger.e('Error creating block', e.toString());
      throw Exception('Failed to create block');
    }
  }

  @override
  Future<void> addBlock(BlockEntity block) async {
    try {
      final db = await _database.database;
      AppLogger.d('Adding block to DB', 'db:block:add ${block.toJson()}');
      await db.insert(
        'blocks',
        block.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      AppLogger.e('Error adding block', e.toString());
      throw Exception('Failed to add block');
    }
  }

  @override
  Future<List<TransactionEntity>> getTransactionHistory() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        orderBy: 'timestamp DESC',
      );

      return List.generate(maps.length, (i) {
        final transaction = TransactionEntity.fromJson(maps[i]);
        AppLogger.d('Transaction from DB', 'db:transaction:get ${transaction.toJson()}');
        return transaction;
      });
    } catch (e) {
      AppLogger.e('Error retrieving transaction history', e.toString());
      throw Exception('Failed to retrieve transaction history');
    }
  }

  @override
  Future<List<BlockEntity>> getBlockchain() async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'blocks',
        orderBy: 'timestamp ASC',
      );

      return List.generate(maps.length, (i) {
        final block = BlockEntity.fromJson(maps[i]);
        AppLogger.d('Block from DB', 'db:block:get ${block.toJson()}');
        return block;
      });
    } catch (e) {
      AppLogger.e('Error retrieving blockchain', e.toString());
      throw Exception('Failed to retrieve blockchain');
    }
  }

  @override
  Future<bool> validateChain() async {
    try {
      final blocks = await getBlockchain();

      if (blocks.isEmpty) return true;

      for (int i = 1; i < blocks.length; i++) {
        final currentBlock = blocks[i];
        final previousBlock = blocks[i - 1];

        if (currentBlock.previousHash != previousBlock.hash) {
          return false;
        }

        final blockData = {
          'previousHash': currentBlock.previousHash,
          'timestamp': currentBlock.timestamp.toIso8601String(),
          'transactionIds': currentBlock.transactionIds,
          'merkleRoot': currentBlock.merkleRoot,
          'nonce': currentBlock.nonce,
        };

        if (_calculateHash(blockData) != currentBlock.hash) {
          AppLogger.e('Block hash mismatch', 'Expected: ${currentBlock.hash}, Calculated: ${_calculateHash(blockData)}');
          return false;
        }
      }

      AppLogger.i('Blockchain validation successful');
      return true;
    } catch (e) {
      AppLogger.e('Error validating blockchain', e.toString());
      throw Exception('Failed to validate blockchain');
    }
  }

  @override
  Future<TransactionEntity?> getTransactionById(String id) async {
    try {
      final db = await _database.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'transactions',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        final transaction = TransactionEntity.fromJson(maps.first);
        AppLogger.d('Transaction from DB by ID', transaction.toJson());
        return transaction;
      }

      AppLogger.w('Transaction not found for ID', id);
      return null;
    } catch (e) {
      AppLogger.e('Error retrieving transaction by ID', e.toString());
      throw Exception('Failed to retrieve transaction by ID');
    }
  }

  @override
  Future<BlockEntity?> getLatestBlock() async {
   try {
     final db = await _database.database;
     final List<Map<String, dynamic>> maps = await db.query(
       'blocks',
       orderBy: 'timestamp DESC',
       limit: 1,
     );

     if (maps.isNotEmpty) {
       final block = BlockEntity.fromJson(maps.first);
       AppLogger.d('Latest block from DB', block.toJson());
       return block;
     }

      AppLogger.w('No blocks found in the database');
     return null;
   } catch (e) {
     AppLogger.e('Error retrieving latest block', e.toString());
     throw Exception('Failed to retrieve latest block');
   }
  }

  @override
  Future<double> getBalance(String publicKey) async {
    try {
      final transactions = await getTransactionHistory();
      double balance = 1000.0; // Starting balance

      for (final transaction in transactions) {
        if (transaction.receiverPublicKey == publicKey) {
          balance += transaction.amount.toDouble();
        }
        if (transaction.senderPublicKey == publicKey) {
          balance -= transaction.amount.toDouble();
        }
      }

      return balance;
    } catch (e) {
      AppLogger.e('Error retrieving balance', e.toString());
      throw Exception('Failed to retrieve balance');
    }
  }

  String _calculateHash(Map<String, dynamic> blockData) {
    try {
      final input = jsonEncode(blockData);
      final bytes = utf8.encode(input);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      AppLogger.e('Error calculating hash', e.toString());
      throw Exception('Failed to calculate hash');
    }
  }

  String _calculateMerkleRoot(List<String> transactionIds) {
    try {
      if (transactionIds.isEmpty) return '0';

      List<String> hashes = transactionIds.map((id) {
        final bytes = utf8.encode(id);
        return sha256.convert(bytes).toString();
      }).toList();

      while (hashes.length > 1) {
        List<String> newLevel = [];

        for (int i = 0; i < hashes.length; i += 2) {
          String left = hashes[i];
          String right = i + 1 < hashes.length ? hashes[i + 1] : left;
          String combined = left + right;
          final bytes = utf8.encode(combined);
          newLevel.add(sha256.convert(bytes).toString());
        }

        hashes = newLevel;
      }

      return hashes.first;
    } catch (e) {
      AppLogger.e('Error calculating Merkle root', e.toString());
      throw Exception('Failed to calculate Merkle root');
    }
  }
}