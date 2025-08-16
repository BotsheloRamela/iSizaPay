import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:isiza_pay/services/device_identity_service.dart';

enum HandshakeStatus {
  disconnected,
  initiating,
  waitingForVerification,
  verifying,
  establishingSession,
  secured,
  failed,
}

enum VerificationMode {
  visual,
  pin,
}

class HandshakeSession {
  final String sessionId;
  final String deviceId;
  final String deviceName;
  final ECPublicKey remotePublicKey;
  final HandshakeStatus status;
  final VerificationMode verificationMode;
  final String? verificationCode;
  final String? pin;
  final Uint8List? sessionKey;
  final String? sessionNonce;
  final DateTime createdAt;

  HandshakeSession({
    required this.sessionId,
    required this.deviceId,
    required this.deviceName,
    required this.remotePublicKey,
    required this.status,
    required this.verificationMode,
    this.verificationCode,
    this.pin,
    this.sessionKey,
    this.sessionNonce,
    required this.createdAt,
  });

  HandshakeSession copyWith({
    HandshakeStatus? status,
    String? verificationCode,
    String? pin,
    Uint8List? sessionKey,
    String? sessionNonce,
  }) {
    return HandshakeSession(
      sessionId: sessionId,
      deviceId: deviceId,
      deviceName: deviceName,
      remotePublicKey: remotePublicKey,
      status: status ?? this.status,
      verificationMode: verificationMode,
      verificationCode: verificationCode ?? this.verificationCode,
      pin: pin ?? this.pin,
      sessionKey: sessionKey ?? this.sessionKey,
      sessionNonce: sessionNonce ?? this.sessionNonce,
      createdAt: createdAt,
    );
  }
}

class SecureMessage {
  final String type;
  final Map<String, dynamic> data;
  final String signature;
  final DateTime timestamp;
  final String sessionNonce;

  SecureMessage({
    required this.type,
    required this.data,
    required this.signature,
    required this.timestamp,
    required this.sessionNonce,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'signature': signature,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'sessionNonce': sessionNonce,
    };
  }

  static SecureMessage fromJson(Map<String, dynamic> json) {
    return SecureMessage(
      type: json['type'],
      data: Map<String, dynamic>.from(json['data']),
      signature: json['signature'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      sessionNonce: json['sessionNonce'],
    );
  }

  String getSignableData() {
    return '$type${jsonEncode(data)}${timestamp.millisecondsSinceEpoch}$sessionNonce';
  }
}

class SecurityHandshakeService {
  final DeviceIdentityService _deviceIdentity;
  final Map<String, HandshakeSession> _activeSessions = {};
  
  Function(String sessionId, HandshakeSession session)? onSessionUpdated;
  Function(String sessionId, SecureMessage message)? onSecureMessageReceived;

  SecurityHandshakeService(this._deviceIdentity);

  Future<HandshakeSession> initiateHandshake({
    required String deviceId,
    required String deviceName,
    required String remotePublicKeyStr,
    required VerificationMode verificationMode,
  }) async {
    final identity = await _deviceIdentity.getOrCreateDeviceIdentity();
    final remotePublicKey = _decodeECPublicKey(remotePublicKeyStr);
    
    final sessionId = _generateSessionId();
    
    String? verificationCode;
    String? pin;
    
    if (verificationMode == VerificationMode.visual) {
      final localPublicKeyStr = _encodeECPublicKey(identity.publicKey);
      verificationCode = _deviceIdentity.generateVerificationCode(
        localPublicKeyStr,
        remotePublicKeyStr,
      );
    } else {
      pin = _deviceIdentity.generatePIN();
    }

    final session = HandshakeSession(
      sessionId: sessionId,
      deviceId: deviceId,
      deviceName: deviceName,
      remotePublicKey: remotePublicKey,
      status: HandshakeStatus.waitingForVerification,
      verificationMode: verificationMode,
      verificationCode: verificationCode,
      pin: pin,
      createdAt: DateTime.now(),
    );

    _activeSessions[sessionId] = session;
    _notifySessionUpdate(sessionId, session);
    
    return session;
  }

  Future<bool> confirmVerification(String sessionId, {String? enteredPin}) async {
    final session = _activeSessions[sessionId];
    if (session == null) return false;

    bool verified = false;
    
    if (session.verificationMode == VerificationMode.visual) {
      verified = true;
    } else if (session.verificationMode == VerificationMode.pin && enteredPin != null) {
      verified = enteredPin == session.pin;
    }

    if (verified) {
      final securedSession = await _establishSecureSession(session);
      _activeSessions[sessionId] = securedSession;
      _notifySessionUpdate(sessionId, securedSession);
      return true;
    }

    final failedSession = session.copyWith(status: HandshakeStatus.failed);
    _activeSessions[sessionId] = failedSession;
    _notifySessionUpdate(sessionId, failedSession);
    return false;
  }

  Future<HandshakeSession> _establishSecureSession(HandshakeSession session) async {
    final identity = await _deviceIdentity.getOrCreateDeviceIdentity();
    
    final sharedSecret = _performECDH(identity.privateKey, session.remotePublicKey);
    
    final sessionKey = _deriveSessionKey(sharedSecret);
    
    final sessionNonce = _generateSessionNonce();

    return session.copyWith(
      status: HandshakeStatus.secured,
      sessionKey: sessionKey,
      sessionNonce: sessionNonce,
    );
  }

  Uint8List _performECDH(ECPrivateKey privateKey, ECPublicKey publicKey) {
    final point = publicKey.Q! * privateKey.d!;
    final x = bigIntToBytes(point!.x!.toBigInteger()!);
    return x;
  }

  String _encodeECPublicKey(ECPublicKey key) {
    final point = key.Q!;
    final x = bigIntToBytes(point.x!.toBigInteger()!);
    final y = bigIntToBytes(point.y!.toBigInteger()!);
    return base64Encode([...x, ...y]);
  }

  ECPublicKey _decodeECPublicKey(String encoded) {
    final bytes = base64Decode(encoded);
    final half = bytes.length ~/ 2;
    final x = BigInt.parse(bytes.take(half).map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
    final y = BigInt.parse(bytes.skip(half).map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
    final domainParams = ECDomainParameters('secp256k1');
    final point = domainParams.curve.createPoint(x, y);
    return ECPublicKey(point, domainParams);
  }

  Uint8List _deriveSessionKey(Uint8List sharedSecret) {
    final digest = sha256.convert(sharedSecret);
    return Uint8List.fromList(digest.bytes);
  }

  String _generateSessionNonce() {
    final random = Random.secure();
    final bytes = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Encode(bytes);
  }

  String _generateSessionId() {
    final random = Random.secure();
    final bytes = Uint8List(8);
    for (int i = 0; i < 8; i++) {
      bytes[i] = random.nextInt(256);
    }
    return base64Encode(bytes);
  }

  Future<SecureMessage> createSecureMessage({
    required String sessionId,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    final session = _activeSessions[sessionId];
    if (session?.status != HandshakeStatus.secured || session == null) {
      throw StateError('Session not secured');
    }

    final identity = await _deviceIdentity.getOrCreateDeviceIdentity();
    final timestamp = DateTime.now();
    
    final message = SecureMessage(
      type: type,
      data: data,
      signature: '',
      timestamp: timestamp,
      sessionNonce: session.sessionNonce ?? '',
    );

    final signature = _signMessage(message, identity.privateKey);
    
    return SecureMessage(
      type: message.type,
      data: message.data,
      signature: signature,
      timestamp: message.timestamp,
      sessionNonce: message.sessionNonce,
    );
  }

  Future<bool> verifySecureMessage(String sessionId, SecureMessage message) async {
    final session = _activeSessions[sessionId];
    if (session?.status != HandshakeStatus.secured || session == null) {
      return false;
    }

    final currentTime = DateTime.now();
    if (currentTime.difference(message.timestamp).inSeconds > 30) {
      return false;
    }

    if (message.sessionNonce != (session.sessionNonce ?? '')) {
      return false;
    }

    return session.remotePublicKey != null && _verifyMessageSignature(message, session.remotePublicKey!);
  }

  String _signMessage(SecureMessage message, ECPrivateKey privateKey) {
    final signer = ECDSASigner(SHA256Digest());
    signer.init(true, PrivateKeyParameter(privateKey));
    
    final dataBytes = utf8.encode(message.getSignableData());
    final signature = signer.generateSignature(dataBytes);
    
    final r = bigIntToBytes((signature as ECSignature).r);
    final s = bigIntToBytes(signature.s);
    
    return base64Encode([...r, ...s]);
  }

  bool _verifyMessageSignature(SecureMessage message, ECPublicKey publicKey) {
    try {
      final signatureBytes = base64Decode(message.signature);
      final half = signatureBytes.length ~/ 2;
      
      final r = BigInt.parse(signatureBytes.take(half).map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
      final s = BigInt.parse(signatureBytes.skip(half).map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
      
      final signature = ECSignature(r, s);
      
      final verifier = ECDSASigner(SHA256Digest());
      verifier.init(false, PublicKeyParameter(publicKey));
      
      final dataBytes = utf8.encode(message.getSignableData());
      return verifier.verifySignature(dataBytes, signature);
    } catch (e) {
      return false;
    }
  }

  Future<void> handleIncomingMessage(String deviceId, Map<String, dynamic> messageData) async {
    if (messageData['type'] == 'handshake_request') {
      await _handleHandshakeRequest(deviceId, messageData);
    } else if (messageData['type'] == 'secure_message') {
      await _handleSecureMessage(deviceId, messageData);
    }
  }

  Future<void> _handleHandshakeRequest(String deviceId, Map<String, dynamic> data) async {
    try {
      final beacon = DiscoveryBeacon.fromJson(data['beacon']);
      if (!_deviceIdentity.verifyDiscoveryBeacon(beacon)) {
        return;
      }

      final verificationMode = VerificationMode.values[data['verification_mode']];
      
      await initiateHandshake(
        deviceId: deviceId,
        deviceName: beacon.deviceName,
        remotePublicKeyStr: beacon.publicKey,
        verificationMode: verificationMode,
      );
    } catch (e) {
    }
  }

  Future<void> _handleSecureMessage(String deviceId, Map<String, dynamic> data) async {
    try {
      final sessionId = data['session_id'];
      final message = SecureMessage.fromJson(data['message']);
      
      if (await verifySecureMessage(sessionId, message)) {
        if (onSecureMessageReceived != null) {
          onSecureMessageReceived!(sessionId, message);
        }
      }
    } catch (e) {
    }
  }

  void _notifySessionUpdate(String sessionId, HandshakeSession session) {
    if (onSessionUpdated != null) {
      onSessionUpdated!(sessionId, session);
    }
  }

  HandshakeSession? getSession(String sessionId) {
    return _activeSessions[sessionId];
  }

  List<HandshakeSession> getActiveSessions() {
    return _activeSessions.values.toList();
  }

  void removeSession(String sessionId) {
    _activeSessions.remove(sessionId);
  }

  void clearExpiredSessions() {
    final now = DateTime.now();
    final expiredSessions = _activeSessions.entries
        .where((entry) => now.difference(entry.value.createdAt).inMinutes > 10)
        .map((entry) => entry.key)
        .toList();
    
    for (final sessionId in expiredSessions) {
      _activeSessions.remove(sessionId);
    }
  }
}