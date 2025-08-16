import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

Uint8List bigIntToBytes(BigInt bigInt) {
  final bytes = <int>[];
  var value = bigInt;
  if (value == BigInt.zero) {
    return Uint8List.fromList([0]);
  }
  while (value > BigInt.zero) {
    bytes.insert(0, (value & BigInt.from(0xff)).toInt());
    value = value >> 8;
  }
  return Uint8List.fromList(bytes);
}

class DeviceIdentity {
  final ECPrivateKey privateKey;
  final ECPublicKey publicKey;
  final String deviceID;
  final String deviceName;

  DeviceIdentity({
    required this.privateKey,
    required this.publicKey,
    required this.deviceID,
    required this.deviceName,
  });

  Map<String, dynamic> toJson() {
    return {
      'privateKey': _encodeECPrivateKey(privateKey),
      'publicKey': _encodeECPublicKey(publicKey),
      'deviceID': deviceID,
      'deviceName': deviceName,
    };
  }

  static DeviceIdentity fromJson(Map<String, dynamic> json) {
    return DeviceIdentity(
      privateKey: _decodeECPrivateKey(json['privateKey']),
      publicKey: _decodeECPublicKey(json['publicKey']),
      deviceID: json['deviceID'],
      deviceName: json['deviceName'],
    );
  }

  static String _encodeECPrivateKey(ECPrivateKey key) {
    return base64Encode(bigIntToBytes(key.d!));
  }

  static String _encodeECPublicKey(ECPublicKey key) {
    final point = key.Q!;
    final x = bigIntToBytes(point.x!.toBigInteger()!);
    final y = bigIntToBytes(point.y!.toBigInteger()!);
    return base64Encode([...x, ...y]);
  }

  static ECPrivateKey _decodeECPrivateKey(String encoded) {
    final bytes = base64Decode(encoded);
    final d = BigInt.parse(bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
    final domainParams = ECDomainParameters('secp256k1');
    return ECPrivateKey(d, domainParams);
  }

  static ECPublicKey _decodeECPublicKey(String encoded) {
    final bytes = base64Decode(encoded);
    final half = bytes.length ~/ 2;
    final x = BigInt.parse(bytes.take(half).map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
    final y = BigInt.parse(bytes.skip(half).map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
    final domainParams = ECDomainParameters('secp256k1');
    final point = domainParams.curve.createPoint(x, y);
    return ECPublicKey(point, domainParams);
  }
}

class DiscoveryBeacon {
  final String deviceID;
  final String publicKey;
  final String deviceName;
  final DateTime timestamp;
  final String signature;

  DiscoveryBeacon({
    required this.deviceID,
    required this.publicKey,
    required this.deviceName,
    required this.timestamp,
    required this.signature,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceID': deviceID,
      'publicKey': publicKey,
      'deviceName': deviceName,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'signature': signature,
    };
  }

  static DiscoveryBeacon fromJson(Map<String, dynamic> json) {
    return DiscoveryBeacon(
      deviceID: json['deviceID'],
      publicKey: json['publicKey'],
      deviceName: json['deviceName'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      signature: json['signature'],
    );
  }

  String getSignableData() {
    return '$deviceID$publicKey$deviceName${timestamp.millisecondsSinceEpoch}';
  }
}

class DeviceIdentityService {
  static const String _dbName = 'device_identity.db';
  static const String _tableName = 'device_identity';
  
  Database? _database;
  DeviceIdentity? _currentIdentity;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id INTEGER PRIMARY KEY,
            identity_data TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<DeviceIdentity> getOrCreateDeviceIdentity() async {
    if (_currentIdentity != null) {
      return _currentIdentity!;
    }

    final db = await database;
    final results = await db.query(_tableName, limit: 1);
    
    if (results.isNotEmpty) {
      final identityData = jsonDecode(results.first['identity_data'] as String);
      _currentIdentity = DeviceIdentity.fromJson(identityData);
      return _currentIdentity!;
    }

    _currentIdentity = await _generateNewIdentity();
    await _saveIdentity(_currentIdentity!);
    return _currentIdentity!;
  }

  Future<DeviceIdentity> _generateNewIdentity() async {
    final keyPair = _generateECKeyPair();
    final publicKeyHash = _hashPublicKey(keyPair.publicKey);
    final deviceName = await _generateDeviceName();

    return DeviceIdentity(
      privateKey: keyPair.privateKey,
      publicKey: keyPair.publicKey,
      deviceID: publicKeyHash,
      deviceName: deviceName,
    );
  }

  AsymmetricKeyPair<ECPublicKey, ECPrivateKey> _generateECKeyPair() {
    final keyGen = ECKeyGenerator();
    final random = FortunaRandom();
    
    final seed = Uint8List(32);
    final secureRandom = Random.secure();
    for (int i = 0; i < 32; i++) {
      seed[i] = secureRandom.nextInt(256);
    }
    random.seed(KeyParameter(seed));

    final params = ECKeyGeneratorParameters(ECCurve_secp256k1());
    keyGen.init(ParametersWithRandom(params, random));

    final keyPair = keyGen.generateKeyPair();
    return AsymmetricKeyPair<ECPublicKey, ECPrivateKey>(
      keyPair.publicKey as ECPublicKey,
      keyPair.privateKey as ECPrivateKey,
    );
  }

  String _hashPublicKey(ECPublicKey publicKey) {
    final point = publicKey.Q!;
    final x = bigIntToBytes(point.x!.toBigInteger()!);
    final y = bigIntToBytes(point.y!.toBigInteger()!);
    final publicKeyBytes = Uint8List.fromList([...x, ...y]);
    
    final digest = sha256.convert(publicKeyBytes);
    return digest.toString().substring(0, 16);
  }

  Future<String> _generateDeviceName() async {
    final adjectives = ['Swift', 'Bright', 'Quick', 'Smart', 'Secure', 'Fast', 'Safe', 'Strong'];
    final nouns = ['Phone', 'Device', 'Mobile', 'Wallet', 'Pay', 'Bank', 'Card', 'Cash'];
    
    final random = Random.secure();
    final adjective = adjectives[random.nextInt(adjectives.length)];
    final noun = nouns[random.nextInt(nouns.length)];
    final number = random.nextInt(1000);
    
    return '$adjective$noun$number';
  }

  Future<void> _saveIdentity(DeviceIdentity identity) async {
    final db = await database;
    await db.delete(_tableName);
    await db.insert(_tableName, {
      'identity_data': jsonEncode(identity.toJson()),
    });
  }

  DiscoveryBeacon createDiscoveryBeacon() {
    if (_currentIdentity == null) {
      throw StateError('Device identity not initialized');
    }

    final identity = _currentIdentity!;
    final timestamp = DateTime.now();
    final beacon = DiscoveryBeacon(
      deviceID: identity.deviceID,
      publicKey: DeviceIdentity._encodeECPublicKey(identity.publicKey),
      deviceName: identity.deviceName,
      timestamp: timestamp,
      signature: '',
    );

    final signature = _signData(beacon.getSignableData(), identity.privateKey);
    return DiscoveryBeacon(
      deviceID: beacon.deviceID,
      publicKey: beacon.publicKey,
      deviceName: beacon.deviceName,
      timestamp: beacon.timestamp,
      signature: signature,
    );
  }

  bool verifyDiscoveryBeacon(DiscoveryBeacon beacon) {
    try {
      final publicKey = DeviceIdentity._decodeECPublicKey(beacon.publicKey);
      final publicKeyHash = _hashPublicKey(publicKey);
      
      if (publicKeyHash != beacon.deviceID) {
        return false;
      }

      final currentTime = DateTime.now();
      if (currentTime.difference(beacon.timestamp).inSeconds > 30) {
        return false;
      }

      return _verifySignature(beacon.getSignableData(), beacon.signature, publicKey);
    } catch (e) {
      return false;
    }
  }

  String _signData(String data, ECPrivateKey privateKey) {
    final signer = ECDSASigner(SHA256Digest());
    signer.init(true, PrivateKeyParameter(privateKey));
    
    final dataBytes = utf8.encode(data);
    final signature = signer.generateSignature(dataBytes);
    
    final r = bigIntToBytes((signature as ECSignature).r);
    final s = bigIntToBytes(signature.s);
    
    return base64Encode([...r, ...s]);
  }

  bool _verifySignature(String data, String signatureStr, ECPublicKey publicKey) {
    try {
      final signatureBytes = base64Decode(signatureStr);
      final half = signatureBytes.length ~/ 2;
      
      final r = BigInt.parse(signatureBytes.take(half).map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
      final s = BigInt.parse(signatureBytes.skip(half).map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
      
      final signature = ECSignature(r, s);
      
      final verifier = ECDSASigner(SHA256Digest());
      verifier.init(false, PublicKeyParameter(publicKey));
      
      final dataBytes = utf8.encode(data);
      return verifier.verifySignature(dataBytes, signature);
    } catch (e) {
      return false;
    }
  }

  String generateVerificationCode(String localPublicKey, String remotePublicKey) {
    final combined = localPublicKey + remotePublicKey;
    final hash = sha256.convert(utf8.encode(combined));
    final hex = hash.toString();
    
    final code = hex.substring(0, 6).toUpperCase();
    return '${code.substring(0, 3)}${code.substring(3, 6)}';
  }

  String generatePIN() {
    final random = Random.secure();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  void dispose() {
    _database?.close();
    _database = null;
  }
}