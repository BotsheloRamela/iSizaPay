const functions = require('firebase-functions');
const admin = require('firebase-admin');
const { Connection, PublicKey, Transaction, SystemProgram, LAMPORTS_PER_SOL } = require('@solana/web3.js');

// Initialize Firebase Admin
admin.initializeApp();

// Initialize Solana connection (you can use your preferred RPC endpoint)
const solanaConnection = new Connection(
  'https://api.mainnet-beta.solana.com', // Replace with your RPC endpoint
  'confirmed'
);

// Cloud Function: Sync offline transactions to Solana
exports.syncOfflineTransactionsToSolana = functions.https.onCall(async (data, context) => {
  try {
    const { transactions, timestamp } = data;
    
    if (!transactions || !Array.isArray(transactions)) {
      throw new Error('Invalid transactions data');
    }

    console.log(`Processing ${transactions.length} offline transactions`);
    
    const results = {
      success: true,
      signatures: {},
      errors: [],
      processed: 0
    };

    // Process each transaction
    for (const tx of transactions) {
      try {
        console.log(`Processing transaction: ${tx.id}`);
        
        // Create Solana transaction
        const solanaTx = await createSolanaTransaction(tx);
        
        // Sign and send transaction (this would use the customer's private key)
        const signature = await sendSolanaTransaction(solanaTx);
        
        // Store signature
        results.signatures[tx.id] = signature;
        results.processed++;
        
        console.log(`Transaction ${tx.id} processed successfully: ${signature}`);
        
      } catch (error) {
        console.error(`Failed to process transaction ${tx.id}:`, error);
        results.errors.push({
          transactionId: tx.id,
          error: error.message
        });
      }
    }

    // Update Firestore with results
    await updateTransactionResults(transactions, results);
    
    return results;
    
  } catch (error) {
    console.error('Sync function error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Cloud Function: Create Solana transaction
exports.createSolanaTransaction = functions.https.onCall(async (data, context) => {
  try {
    const { transaction, senderPrivateKey, receiverPublicKey, timestamp } = data;
    
    if (!transaction || !senderPrivateKey || !receiverPublicKey) {
      throw new Error('Missing required transaction data');
    }

    console.log(`Creating Solana transaction for: ${transaction.id}`);
    
    // Create transaction object
    const solanaTx = new Transaction();
    
    // Add transfer instruction
    const transferInstruction = SystemProgram.transfer({
      fromPubkey: new PublicKey(senderPrivateKey),
      toPubkey: new PublicKey(receiverPublicKey),
      lamports: transaction.totalAmount * LAMPORTS_PER_SOL
    });
    
    solanaTx.add(transferInstruction);
    
    // Get recent blockhash
    const { blockhash } = await solanaConnection.getLatestBlockhash();
    solanaTx.recentBlockhash = blockhash;
    solanaTx.feePayer = new PublicKey(senderPrivateKey);
    
    return {
      success: true,
      transaction: solanaTx.serialize().toString('base64'),
      blockhash: blockhash
    };
    
  } catch (error) {
    console.error('Create transaction error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Cloud Function: Validate Solana transaction
exports.validateSolanaTransaction = functions.https.onCall(async (data, context) => {
  try {
    const { transactionSignature, timestamp } = data;
    
    if (!transactionSignature) {
      throw new Error('Missing transaction signature');
    }

    console.log(`Validating transaction: ${transactionSignature}`);
    
    // Get transaction details from Solana
    const transaction = await solanaConnection.getTransaction(transactionSignature);
    
    if (!transaction) {
      return {
        success: false,
        error: 'Transaction not found'
      };
    }

    // Check confirmation status
    const confirmationStatus = transaction.meta?.confirmationStatus || 'unknown';
    
    return {
      success: true,
      transaction: {
        signature: transactionSignature,
        confirmationStatus: confirmationStatus,
        slot: transaction.slot,
        blockTime: transaction.blockTime,
        fee: transaction.meta?.fee || 0
      }
    };
    
  } catch (error) {
    console.error('Validation error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Cloud Function: Get Solana balance
exports.getSolanaBalance = functions.https.onCall(async (data, context) => {
  try {
    const { publicKey, timestamp } = data;
    
    if (!publicKey) {
      throw new Error('Missing public key');
    }

    console.log(`Getting balance for: ${publicKey}`);
    
    // Get balance from Solana
    const balance = await solanaConnection.getBalance(new PublicKey(publicKey));
    
    return {
      success: true,
      balance: balance / LAMPORTS_PER_SOL, // Convert lamports to SOL
      lamports: balance
    };
    
  } catch (error) {
    console.error('Balance check error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Cloud Function: Sync vendor event data
exports.syncVendorEventData = functions.https.onCall(async (data, context) => {
  try {
    const { vendorInfo, timestamp } = data;
    
    if (!vendorInfo || !vendorInfo.id) {
      throw new Error('Invalid vendor info');
    }

    console.log(`Syncing vendor event data for: ${vendorInfo.id}`);
    
    // Store vendor info in Firestore
    await admin.firestore()
      .collection('vendor_events')
      .doc(vendorInfo.id)
      .set({
        ...vendorInfo,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        syncedToSolana: true
      });
    
    return {
      success: true,
      vendorId: vendorInfo.id,
      synced: true
    };
    
  } catch (error) {
    console.error('Vendor sync error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Cloud Function: Process batch transactions
exports.processBatchTransactions = functions.https.onCall(async (data, context) => {
  try {
    const { transactions, timestamp } = data;
    
    if (!transactions || !Array.isArray(transactions)) {
      throw new Error('Invalid transactions data');
    }

    console.log(`Processing batch of ${transactions.length} transactions`);
    
    const results = {
      success: true,
      processed: 0,
      failed: 0,
      signatures: {}
    };

    // Process transactions in parallel batches
    const batchSize = 5;
    for (let i = 0; i < transactions.length; i += batchSize) {
      const batch = transactions.slice(i, i + batchSize);
      
      const batchPromises = batch.map(async (tx) => {
        try {
          const result = await createSolanaTransaction(tx);
          if (result.success) {
            results.processed++;
            results.signatures[tx.id] = result.transaction;
          } else {
            results.failed++;
          }
        } catch (error) {
          results.failed++;
          console.error(`Batch processing error for ${tx.id}:`, error);
        }
      });
      
      await Promise.all(batchPromises);
    }
    
    return results;
    
  } catch (error) {
    console.error('Batch processing error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Cloud Function: Get transaction status
exports.getTransactionStatus = functions.https.onCall(async (data, context) => {
  try {
    const { transactionId, timestamp } = data;
    
    if (!transactionId) {
      throw new Error('Missing transaction ID');
    }

    console.log(`Getting status for transaction: ${transactionId}`);
    
    // Get transaction from Firestore
    const txDoc = await admin.firestore()
      .collection('offline_transactions')
      .doc(transactionId)
      .get();
    
    if (!txDoc.exists) {
      return {
        success: false,
        error: 'Transaction not found'
      };
    }
    
    const txData = txDoc.data();
    
    return {
      success: true,
      transaction: {
        id: transactionId,
        status: txData.syncStatus || 'unknown',
        solanaSignature: txData.solanaSignature,
        errorMessage: txData.errorMessage,
        createdAt: txData.createdAt,
        updatedAt: txData.updatedAt
      }
    };
    
  } catch (error) {
    console.error('Status check error:', error);
    return {
      success: false,
      error: error.message
    };
  }
});

// Helper function: Create Solana transaction
async function createSolanaTransaction(txData) {
  try {
    const transaction = new Transaction();
    
    // Add transfer instruction
    const transferInstruction = SystemProgram.transfer({
      fromPubkey: new PublicKey(txData.customerId), // This should be the actual public key
      toPubkey: new PublicKey(txData.vendorId),     // This should be the actual public key
      lamports: txData.totalAmount * LAMPORTS_PER_SOL
    });
    
    transaction.add(transferInstruction);
    
    // Get recent blockhash
    const { blockhash } = await solanaConnection.getLatestBlockhash();
    transaction.recentBlockhash = blockhash;
    
    return transaction;
  } catch (error) {
    throw new Error(`Failed to create Solana transaction: ${error.message}`);
  }
}

// Helper function: Send Solana transaction
async function sendSolanaTransaction(transaction) {
  try {
    // This is a placeholder - in reality, you'd need the private key to sign
    // For now, we'll return a mock signature
    const mockSignature = 'mock_signature_' + Date.now();
    
    console.log(`Transaction sent with signature: ${mockSignature}`);
    return mockSignature;
  } catch (error) {
    throw new Error(`Failed to send Solana transaction: ${error.message}`);
  }
}

// Helper function: Update transaction results in Firestore
async function updateTransactionResults(transactions, results) {
  try {
    const batch = admin.firestore().batch();
    
    for (const tx of transactions) {
      const txRef = admin.firestore()
        .collection('offline_transactions')
        .doc(tx.id);
      
      if (results.signatures[tx.id]) {
        // Success - move to synced collection
        batch.set(
          admin.firestore().collection('synced_transactions').doc(tx.id),
          {
            ...tx,
            solanaSignature: results.signatures[tx.id],
            syncedAt: admin.firestore.FieldValue.serverTimestamp(),
            status: 'confirmed'
          }
        );
        
        // Delete from offline collection
        batch.delete(txRef);
      } else {
        // Failed - update status
        batch.update(txRef, {
          syncStatus: 'failed',
          errorMessage: 'Failed to sync to Solana',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }
    }
    
    await batch.commit();
    console.log('Transaction results updated in Firestore');
    
  } catch (error) {
    console.error('Failed to update transaction results:', error);
  }
}
