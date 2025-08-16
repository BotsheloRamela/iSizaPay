import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class BlockchainDatabase {
  static final BlockchainDatabase _instance = BlockchainDatabase._internal();
  factory BlockchainDatabase() => _instance;
  BlockchainDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'blockchain.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE blocks (
        hash TEXT PRIMARY KEY,
        previousHash TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        transactionIds TEXT NOT NULL,
        nonce INTEGER NOT NULL,
        merkleRoot TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        senderPublicKey TEXT NOT NULL,
        receiverPublicKey TEXT NOT NULL,
        amount REAL NOT NULL,
        timestamp TEXT NOT NULL,
        signature TEXT NOT NULL,
        previousBlockHash TEXT NOT NULL,
        status TEXT NOT NULL,
        blockchainTxId TEXT,
        blockchainError TEXT,
        confirmedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_sender ON transactions(senderPublicKey)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_receiver ON transactions(receiverPublicKey)
    ''');

    await db.execute('''
      CREATE INDEX idx_transactions_timestamp ON transactions(timestamp)
    ''');

    await db.execute('''
      CREATE INDEX idx_blocks_timestamp ON blocks(timestamp)
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}