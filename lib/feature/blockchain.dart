// lib/features/blockchain/blockchain_module.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/repositories/blockchain_repository_impl.dart';
import 'data/solscan/solscan_service.dart';
import 'domain/repositories/blockchain_repository.dart';
import 'package:solana/solana.dart';
import 'package:sqflite/sqflite.dart';

final solanaClientProvider = Provider((ref) => RpcClient('https://api.mainnet-beta.solana.com'));
final localDbProvider = Provider<Database>((ref) => throw UnimplementedError()); // implement SQLite init
final solscanProvider = Provider((ref) => SolscanService());

final blockchainRepositoryProvider = Provider<BlockchainRepository>(
  (ref) => BlockchainRepositoryImpl(
    client: ref.read(solanaClientProvider),
    localDb: ref.read(localDbProvider),
    solscan: ref.read(solscanProvider),
  ),
);
