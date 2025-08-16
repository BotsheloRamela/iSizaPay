import 'dart:convert';
import 'package:pointycastle/export.dart';
import 'package:isiza_pay/services/device_identity_service.dart';
import 'package:isiza_pay/services/security_handshake_service.dart';

class SecureTransaction {
  final String transactionID;
  final String fromDeviceID;
  final String toDeviceID;
  final double amount;
  final DateTime timestamp;
  final String sessionNonce;
  final String signature;
  final Map<String, dynamic> metadata;

  SecureTransaction({
    required this.transactionID,
    required this.fromDeviceID,
    required this.toDeviceID,
    required this.amount,
    required this.timestamp,
    required this.sessionNonce,
    required this.signature,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'transactionID': transactionID,
      'fromDeviceID': fromDeviceID,
      'toDeviceID': toDeviceID,
      'amount': amount,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'sessionNonce': sessionNonce,
      'signature': signature,
      'metadata': metadata,
    };
  }

  static SecureTransaction fromJson(Map<String, dynamic> json) {
    return SecureTransaction(
      transactionID: json['transactionID'],
      fromDeviceID: json['fromDeviceID'],
      toDeviceID: json['toDeviceID'],
      amount: (json['amount'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      sessionNonce: json['sessionNonce'],
      signature: json['signature'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  String getSignableData() {
    return '$transactionID$fromDeviceID$toDeviceID$amount${timestamp.millisecondsSinceEpoch}$sessionNonce';
  }
}

class TransactionValidationResult {
  final bool isValid;
  final String? error;
  final List<String> warnings;

  TransactionValidationResult({
    required this.isValid,
    this.error,
    this.warnings = const [],
  });
}

class SecureTransactionService {
  final DeviceIdentityService _deviceIdentity;
  final SecurityHandshakeService _handshakeService;
  final List<SecureTransaction> _transactionHistory = [];
  final Map<String, int> _sessionNonceSequence = {};

  Function(SecureTransaction transaction)? onTransactionReceived;
  Function(SecureTransaction transaction)? onTransactionSent;
  Function(String error)? onTransactionError;

  SecureTransactionService(this._deviceIdentity, this._handshakeService);

  Future<SecureTransaction> createSecureTransaction({
    required String sessionId,
    required String toDeviceID,
    required double amount,
    Map<String, dynamic> metadata = const {},
  }) async {
    final session = _handshakeService.getSession(sessionId);
    if (session?.status != HandshakeStatus.secured || session == null) {
      throw StateError('Session not secured');
    }

    final identity = await _deviceIdentity.getOrCreateDeviceIdentity();
    final transactionID = _generateTransactionID();
    final timestamp = DateTime.now();

    final transaction = SecureTransaction(
      transactionID: transactionID,
      fromDeviceID: identity.deviceID,
      toDeviceID: toDeviceID,
      amount: amount,
      timestamp: timestamp,
      sessionNonce: session.sessionNonce ?? '',
      signature: '',
      metadata: metadata,
    );

    final signature = _signTransaction(transaction, identity.privateKey);
    
    final signedTransaction = SecureTransaction(
      transactionID: transaction.transactionID,
      fromDeviceID: transaction.fromDeviceID,
      toDeviceID: transaction.toDeviceID,
      amount: transaction.amount,
      timestamp: transaction.timestamp,
      sessionNonce: transaction.sessionNonce,
      signature: signature,
      metadata: transaction.metadata,
    );

    _transactionHistory.add(signedTransaction);
    
    if (onTransactionSent != null) {
      onTransactionSent!(signedTransaction);
    }

    return signedTransaction;
  }

  Future<TransactionValidationResult> validateTransaction(
    SecureTransaction transaction,
    String sessionId,
  ) async {
    final warnings = <String>[];

    final session = _handshakeService.getSession(sessionId);
    if (session?.status != HandshakeStatus.secured || session == null) {
      return TransactionValidationResult(
        isValid: false,
        error: 'Session not secured',
      );
    }

    if (transaction.sessionNonce != (session.sessionNonce ?? '')) {
      return TransactionValidationResult(
        isValid: false,
        error: 'Invalid session nonce',
      );
    }

    final currentTime = DateTime.now();
    final timeDifference = currentTime.difference(transaction.timestamp).inSeconds;
    if (timeDifference > 30) {
      return TransactionValidationResult(
        isValid: false,
        error: 'Transaction timestamp too old (${timeDifference}s)',
      );
    }

    if (timeDifference < -5) {
      warnings.add('Transaction timestamp is in the future');
    }

    final currentSequence = _sessionNonceSequence[sessionId] ?? 0;
    _sessionNonceSequence[sessionId] = currentSequence + 1;

    if (transaction.amount <= 0) {
      return TransactionValidationResult(
        isValid: false,
        error: 'Invalid transaction amount',
      );
    }

    if (transaction.amount > 10000) {
      warnings.add('Large transaction amount: \$${transaction.amount}');
    }

    if (session.remotePublicKey == null || !await _verifyTransactionSignature(transaction, session.remotePublicKey!)) {
      return TransactionValidationResult(
        isValid: false,
        error: 'Invalid transaction signature',
      );
    }

    if (_isTransactionDuplicate(transaction)) {
      return TransactionValidationResult(
        isValid: false,
        error: 'Duplicate transaction detected',
      );
    }

    return TransactionValidationResult(
      isValid: true,
      warnings: warnings,
    );
  }

  Future<void> processIncomingTransaction(
    SecureTransaction transaction,
    String sessionId,
  ) async {
    final validationResult = await validateTransaction(transaction, sessionId);
    
    if (!validationResult.isValid) {
      if (onTransactionError != null) {
        onTransactionError!(validationResult.error!);
      }
      return;
    }

    _transactionHistory.add(transaction);

    if (onTransactionReceived != null) {
      onTransactionReceived!(transaction);
    }

    if (validationResult.warnings.isNotEmpty && onTransactionError != null) {
      for (final warning in validationResult.warnings) {
        onTransactionError!('Warning: $warning');
      }
    }
  }

  String _generateTransactionID() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = List.generate(8, (_) => (timestamp % 36).toRadixString(36)).join();
    return 'tx_${timestamp}_$random';
  }

  String _signTransaction(SecureTransaction transaction, ECPrivateKey privateKey) {
    final signer = ECDSASigner(SHA256Digest());
    signer.init(true, PrivateKeyParameter(privateKey));
    
    final dataBytes = utf8.encode(transaction.getSignableData());
    final signature = signer.generateSignature(dataBytes);
    
    final r = bigIntToBytes((signature as ECSignature).r);
    final s = bigIntToBytes(signature.s);
    
    return base64Encode([...r, ...s]);
  }

  Future<bool> _verifyTransactionSignature(
    SecureTransaction transaction,
    ECPublicKey publicKey,
  ) async {
    try {
      final signatureBytes = base64Decode(transaction.signature);
      final half = signatureBytes.length ~/ 2;
      
      final r = BigInt.parse(signatureBytes.take(half).map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
      final s = BigInt.parse(signatureBytes.skip(half).map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
      
      final signature = ECSignature(r, s);
      
      final verifier = ECDSASigner(SHA256Digest());
      verifier.init(false, PublicKeyParameter(publicKey));
      
      final dataBytes = utf8.encode(transaction.getSignableData());
      return verifier.verifySignature(dataBytes, signature);
    } catch (e) {
      return false;
    }
  }

  bool _isTransactionDuplicate(SecureTransaction transaction) {
    return _transactionHistory.any((existing) => 
      existing.transactionID == transaction.transactionID ||
      (existing.fromDeviceID == transaction.fromDeviceID &&
       existing.toDeviceID == transaction.toDeviceID &&
       existing.amount == transaction.amount &&
       existing.timestamp.difference(transaction.timestamp).abs().inSeconds < 10)
    );
  }

  List<SecureTransaction> getTransactionHistory({String? deviceId}) {
    if (deviceId == null) {
      return List.unmodifiable(_transactionHistory);
    }
    
    return _transactionHistory
        .where((tx) => tx.fromDeviceID == deviceId || tx.toDeviceID == deviceId)
        .toList();
  }

  double getBalance(String deviceId) {
    double balance = 0.0;
    
    for (final transaction in _transactionHistory) {
      if (transaction.toDeviceID == deviceId) {
        balance += transaction.amount;
      } else if (transaction.fromDeviceID == deviceId) {
        balance -= transaction.amount;
      }
    }
    
    return balance;
  }

  Map<String, dynamic> getTransactionStats(String deviceId) {
    final deviceTransactions = getTransactionHistory(deviceId: deviceId);
    
    double totalSent = 0;
    double totalReceived = 0;
    int sentCount = 0;
    int receivedCount = 0;
    
    for (final transaction in deviceTransactions) {
      if (transaction.fromDeviceID == deviceId) {
        totalSent += transaction.amount;
        sentCount++;
      } else {
        totalReceived += transaction.amount;
        receivedCount++;
      }
    }
    
    return {
      'totalSent': totalSent,
      'totalReceived': totalReceived,
      'sentCount': sentCount,
      'receivedCount': receivedCount,
      'balance': getBalance(deviceId),
      'transactionCount': deviceTransactions.length,
    };
  }

  List<Map<String, dynamic>> getSecurityAuditLog() {
    final auditLog = <Map<String, dynamic>>[];
    
    for (final transaction in _transactionHistory) {
      auditLog.add({
        'timestamp': transaction.timestamp.toIso8601String(),
        'type': 'transaction',
        'transactionId': transaction.transactionID,
        'fromDevice': transaction.fromDeviceID,
        'toDevice': transaction.toDeviceID,
        'amount': transaction.amount,
        'signatureVerified': true,
        'sessionNonce': transaction.sessionNonce,
      });
    }
    
    return auditLog;
  }

  void clearTransactionHistory() {
    _transactionHistory.clear();
    _sessionNonceSequence.clear();
  }

  void clearExpiredTransactions() {
    final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
    _transactionHistory.removeWhere((tx) => tx.timestamp.isBefore(cutoffTime));
  }
}