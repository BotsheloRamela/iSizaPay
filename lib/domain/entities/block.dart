class BlockEntity {
  final String hash;
  final String previousHash;
  final DateTime timestamp;
  final List<String> transactionIds;
  final int nonce;
  final String merkleRoot;

  BlockEntity({
    required this.hash,
    required this.previousHash,
    required this.timestamp,
    required this.transactionIds,
    required this.nonce,
    required this.merkleRoot,
  });

  BlockEntity copyWith({
    String? hash,
    String? previousHash,
    DateTime? timestamp,
    List<String>? transactionIds,
    int? nonce,
    String? merkleRoot,
  }) {
    return BlockEntity(
      hash: hash ?? this.hash,
      previousHash: previousHash ?? this.previousHash,
      timestamp: timestamp ?? this.timestamp,
      transactionIds: transactionIds ?? this.transactionIds,
      nonce: nonce ?? this.nonce,
      merkleRoot: merkleRoot ?? this.merkleRoot,
    );
  }

  @override
  String toString() {
    return 'BlockEntity(hash: $hash, previousHash: $previousHash, timestamp: $timestamp, transactionIds: $transactionIds, nonce: $nonce, merkleRoot: $merkleRoot)';
  }

  Map<String, dynamic> toJson() {
    return {
      'hash': hash,
      'previousHash': previousHash,
      'timestamp': timestamp.toIso8601String(),
      'transactionIds': transactionIds.join(','),
      'nonce': nonce,
      'merkleRoot': merkleRoot,
    };
  }

  factory BlockEntity.fromJson(Map<String, dynamic> json) {
    return BlockEntity(
      hash: json['hash'] as String,
      previousHash: json['previousHash'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      transactionIds: (json['transactionIds'] as String).isEmpty 
          ? <String>[]
          : (json['transactionIds'] as String).split(','),
      nonce: json['nonce'] as int,
      merkleRoot: json['merkleRoot'] as String,
    );
  }
}