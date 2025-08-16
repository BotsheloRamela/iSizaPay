# IsizaPay Blockchain Guide

Welcome to the IsizaPay blockchain documentation! This guide explains how the blockchain technology works in our offline peer-to-peer payment app in simple, easy-to-understand terms.

## What is a Blockchain?

Think of a blockchain as a **digital ledger** (like a notebook) that keeps track of all money transactions. But instead of being stored in one place, copies of this ledger are stored on many devices, making it very secure and tamper-proof.

## How IsizaPay's Blockchain Works

### 🏗️ The Building Blocks

Our blockchain is made up of two main components:

#### 1. **Transactions** 📝
A transaction is like writing a check. It contains:
- **Sender**: Who is sending the money (their wallet address)
- **Receiver**: Who is receiving the money (their wallet address)  
- **Amount**: How much money is being sent
- **Timestamp**: When the transaction happened
- **Signature**: A digital signature that proves the sender authorized this transaction
- **Previous Block Hash**: A reference to link transactions together

#### 2. **Blocks** 📦
A block is like a page in our ledger that contains:
- **Multiple Transactions**: Several transactions bundled together
- **Hash**: A unique fingerprint for this block
- **Previous Hash**: The fingerprint of the previous block (creating the "chain")
- **Timestamp**: When this block was created
- **Nonce**: A special number used for security (proof-of-work)
- **Merkle Root**: A summary of all transactions in the block

### 🔐 Security Features

#### Digital Signatures
Every transaction is signed using **Solana's Ed25519 cryptography**:
- When you send money, your private key creates a unique signature
- Others can verify this signature using your public key
- This ensures only you can spend your money

#### Proof-of-Work Mining
When creating new blocks, our system:
1. Takes all pending transactions
2. Tries different "nonce" numbers
3. Keeps trying until the block's hash starts with "0000"
4. This process (called "mining") makes blocks very hard to fake

#### Chain Validation
The blockchain constantly checks itself:
- Each block must reference the previous block correctly
- All signatures must be valid
- The math must add up perfectly

### 💾 How Data is Stored

#### On-Device Storage
- Uses **SQLite database** for fast, offline access
- All blockchain data is stored locally on your phone
- Works completely without internet connection

#### Database Structure
```
📁 Blocks Table
  - hash (unique ID)
  - previousHash (links to previous block)
  - timestamp (when created)
  - transactionIds (list of included transactions)
  - nonce (proof-of-work number)
  - merkleRoot (transaction summary)

📁 Transactions Table
  - id (unique ID)
  - senderPublicKey (sender's wallet)
  - receiverPublicKey (receiver's wallet)
  - amount (money being sent)
  - timestamp (when created)
  - signature (cryptographic proof)
  - status (pending/confirmed/failed)
```

### 🔄 Transaction Lifecycle

Here's what happens when you send money:

#### Step 1: Create Transaction
```
👤 User wants to send $50 to friend
💻 App creates transaction with:
  - Sender: your_wallet_address
  - Receiver: friend_wallet_address  
  - Amount: $50
  - Signature: proves it's really you
```

#### Step 2: Sign Transaction
```
🔐 Your private key signs the transaction
✅ Creates unforgeable digital signature
💾 Transaction saved as "pending offline"
```

#### Step 3: Create Block (Mining)
```
📦 System collects pending transactions
🔨 Starts "mining" process:
  - Try nonce = 1, hash = "abc123..." ❌
  - Try nonce = 2, hash = "def456..." ❌  
  - Try nonce = 547, hash = "0000789..." ✅
💎 Block successfully mined!
```

#### Step 4: Add to Chain
```
⛓️ New block added to blockchain
🔍 System validates entire chain
✅ Transaction now confirmed
💰 Balances updated
```

### 🎯 Use Cases in IsizaPay

#### Offline Payments
- **Create transactions** without internet
- **Store securely** on your device
- **Sync later** when online

#### Trust System
- **Verify authenticity** of all transactions
- **Prevent double-spending** 
- **Build reputation** through transaction history

#### Balance Management
- **Track confirmed balance** (blockchain verified)
- **Track available balance** (includes pending transactions)
- **Calculate transaction fees** and limits

### 🛠️ Code Architecture

Our blockchain follows **Clean Architecture** principles:

```
📱 Presentation Layer (UI)
  └── BlockchainViewModel (manages state)

💼 Domain Layer (Business Logic)
  ├── Entities (Transaction, Block)
  ├── Use Cases (CreateTransaction, ValidateChain)
  └── Repository Interface

🗄️ Data Layer (Storage)
  ├── Repository Implementation
  ├── SQLite Database
  └── Solana Crypto Integration
```

### 🔧 Key Components

#### BlockchainNotifier
- Manages overall blockchain state
- Handles wallet key generation
- Coordinates transaction creation

#### Use Cases
- **CreateTransactionUseCase**: Creates and signs new transactions
- **ValidateChainUseCase**: Checks blockchain integrity
- **GetBalanceUseCase**: Calculates wallet balances
- **CreateBlockUseCase**: Mines new blocks

#### Repository
- **Interface**: Defines what blockchain operations are available
- **Implementation**: Handles SQLite storage and retrieval
- **Database**: Manages data persistence and indexing

---

**Need Help?** 
- Check the code in `lib/domain/` for business logic
- Look at `lib/data/` for storage implementation  
- See `test/` for usage examples