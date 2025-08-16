
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isiza_pay/data/repositories/blockchain.dart';
import 'package:isiza_pay/data/solscan/solscan_service.dart';
import 'package:isiza_pay/domain/repositories/blockchain.dart';
import 'package:solana/solana.dart';
import 'package:sqflite/sqflite.dart';

final solanaClientProvider = Provider((ref) => RpcClient('https://api.mainnet-beta.solana.com'));
final localDbProvider = Provider<Database>((ref) => throw UnimplementedError()); // TODO: implement SQLite init
final solscanProvider = Provider((ref) => SolscanService());

final blockchainRepositoryProvider = Provider<BlockchainRepository>(
  (ref) => BlockchainRepositoryImpl(
    client: ref.read(solanaClientProvider),
    localDb: ref.read(localDbProvider),
    solscan: ref.read(solscanProvider),
  ),
);
