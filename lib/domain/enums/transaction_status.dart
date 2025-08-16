
enum TransactionStatus {
  pendingOffline,      // Created offline, not yet submitted to blockchain
  pendingBlockchain,   // Submitted to blockchain, awaiting confirmation
  confirmed,           // Confirmed on blockchain
  failed,              // Failed blockchain submission or confirmation
  rejected,            // Rejected by network
}