import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:isiza_pay/data/database/blockchain_database.dart';
import 'package:isiza_pay/data/repositories/blockchain_repository_impl.dart';
import 'package:isiza_pay/domain/usecases/create_transaction_usecase.dart';
import 'package:isiza_pay/domain/usecases/validate_chain_usecase.dart';
import 'package:isiza_pay/domain/usecases/get_transaction_history_usecase.dart';
import 'package:isiza_pay/domain/usecases/get_balance_usecase.dart';
import 'package:isiza_pay/domain/usecases/create_block_usecase.dart';
import 'package:solana/solana.dart';

void main() {
  group('Blockchain Implementation Tests', () {
    late BlockchainDatabase database;
    late BlockchainRepositoryImpl repository;
    late CreateTransactionUseCase createTransactionUseCase;
    late ValidateChainUseCase validateChainUseCase;
    late GetTransactionHistoryUseCase getTransactionHistoryUseCase;
    late GetBalanceUseCase getBalanceUseCase;
    late CreateBlockUseCase createBlockUseCase;

    setUp(() async {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      
      database = BlockchainDatabase();
      repository = BlockchainRepositoryImpl(database);
      createTransactionUseCase = CreateTransactionUseCase(repository);
      validateChainUseCase = ValidateChainUseCase(repository);
      getTransactionHistoryUseCase = GetTransactionHistoryUseCase(repository);
      getBalanceUseCase = GetBalanceUseCase(repository);
      createBlockUseCase = CreateBlockUseCase(repository);
    });

    test('should create and sign a transaction', () async {
      final senderKeyPair = await Ed25519HDKeyPair.random();
      final receiverKeyPair = await Ed25519HDKeyPair.random();

      final transaction = await createTransactionUseCase.execute(
        senderPublicKey: senderKeyPair.address,
        receiverPublicKey: receiverKeyPair.address,
        amount: 100.0,
        senderKeyPair: senderKeyPair,
      );

      expect(transaction.senderPublicKey, equals(senderKeyPair.address));
      expect(transaction.receiverPublicKey, equals(receiverKeyPair.address));
      expect(transaction.amount, equals(100.0));
      expect(transaction.signature.isNotEmpty, isTrue);
    });

    test('should validate an empty blockchain', () async {
      final isValid = await validateChainUseCase.execute();
      expect(isValid, isTrue);
    });

    test('should create a block with transactions', () async {
      final senderKeyPair = await Ed25519HDKeyPair.random();
      final receiverKeyPair = await Ed25519HDKeyPair.random();

      final transaction = await createTransactionUseCase.execute(
        senderPublicKey: senderKeyPair.address,
        receiverPublicKey: receiverKeyPair.address,
        amount: 50.0,
        senderKeyPair: senderKeyPair,
      );

      final block = await createBlockUseCase.execute([transaction]);

      expect(block.transactionIds, contains(transaction.id));
      expect(block.hash.startsWith('0000'), isTrue);
      expect(block.previousHash, equals('0'));
    });

    test('should calculate balance correctly', () async {
      final senderKeyPair = await Ed25519HDKeyPair.random();
      final receiverKeyPair = await Ed25519HDKeyPair.random();

      await createTransactionUseCase.execute(
        senderPublicKey: senderKeyPair.address,
        receiverPublicKey: receiverKeyPair.address,
        amount: 75.0,
        senderKeyPair: senderKeyPair,
      );

      final senderBalance = await getBalanceUseCase.execute(senderKeyPair.address);
      final receiverBalance = await getBalanceUseCase.execute(receiverKeyPair.address);

      expect(senderBalance, equals(-75.0));
      expect(receiverBalance, equals(75.0));
    });

    test('should retrieve transaction history', () async {
      final senderKeyPair = await Ed25519HDKeyPair.random();
      final receiverKeyPair = await Ed25519HDKeyPair.random();

      await createTransactionUseCase.execute(
        senderPublicKey: senderKeyPair.address,
        receiverPublicKey: receiverKeyPair.address,
        amount: 25.0,
        senderKeyPair: senderKeyPair,
      );

      final history = await getTransactionHistoryUseCase.execute(
        publicKey: senderKeyPair.address,
      );

      expect(history.length, equals(1));
      expect(history.first.senderPublicKey, equals(senderKeyPair.address));
      expect(history.first.amount, equals(25.0));
    });
  });
}