# Isiza Pay 💰

A peer-to-peer blockchain payment app built with Flutter. Send and receive payments offline through secure device-to-device connections, powered by a local blockchain that syncs with Solana.

## ✨ Features

- **Offline P2P Payments** - Send money to nearby devices without internet
- **Blockchain Security** - Local blockchain with Solana cryptography
- **Real-time Discovery** - Find and connect to nearby payment-enabled devices
- **Transaction History** - Complete history of all payments and requests
- **Secure Wallet** - Ed25519 cryptographic key pairs for security
- **Cross-platform** - Works on both iOS and Android

## 🏗️ Architecture

This app follows Clean Architecture principles with MVVM pattern and Riverpod for state management. 

**Key Technologies:**
- **Flutter** - Cross-platform mobile framework
- **Riverpod** - Reactive state management and dependency injection
- **SQLite** - Local blockchain and transaction storage
- **Solana SDK** - Cryptographic operations and signatures
- **Nearby Connections** - P2P device discovery and communication

📖 **[Read the full Architecture Guide](docs/architecture.md)** for detailed explanation of how everything works together.

## 🔗 Blockchain Technology

Our app implements a lightweight blockchain optimized for mobile P2P payments:

- **On-device mining** with proof-of-work
- **Cryptographic signatures** using Solana's Ed25519
- **Offline transaction** queuing and validation
- **Automatic chain validation** and integrity checks

📖 **[Read the Blockchain Guide](docs/blockchain-guide.md)** for technical deep-dive into how the blockchain works.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.7.2 or higher
- Android Studio or VS Code
- iOS/Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/isiza_pay.git
   cd isiza_pay
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Permissions

The app requires the following permissions for P2P functionality:
- **Location** - For nearby device discovery
- **Bluetooth** - For device-to-device communication
- **WiFi** - For high-speed data transfer

## 📱 How to Use

1. **Connect to Devices**
   - Tap "Connect to Devices" to discover nearby users
   - Grant location and bluetooth permissions when prompted
   - Select devices to connect with

2. **Send Payments**
   - Ensure you're connected to at least one device
   - Tap "Send Payment" and enter amount
   - Select recipient from connected devices
   - Confirm transaction

3. **Receive Payments**
   - Tap "Receive" to create a payment request
   - Share your request with nearby users
   - Accept or decline incoming payment requests

4. **View History**
   - Tap the history icon to see all transactions
   - View pending, completed, and failed payments
   - Check your current balance

## 🔮 Upcoming Features

We're working on exciting new features to enhance the payment experience:

- **Event Mode** - Mesh networking for large events and festivals
- **QR Code Payments** - Scan-to-pay functionality
- **Multi-currency Support** - Support for different cryptocurrencies
- **Enhanced Analytics** - Spending insights and transaction analytics

📖 **[See all Upcoming Features](docs/upcoming-features.md)** for detailed roadmap and implementation plans.

## 🧪 Testing

Run the test suite:

```bash
# Unit and widget tests
flutter test

# Integration tests
flutter test integration_test/
```

## 📁 Project Structure

```
lib/
├── core/           # Dependency injection, utilities
├── data/           # Repositories, database, external APIs
├── domain/         # Business logic, entities, use cases
├── presentation/   # UI screens, widgets, view models
├── services/       # Cross-cutting services (P2P, blockchain sync)
└── main.dart       # App entry point

docs/               # Documentation
├── architecture.md     # App architecture explanation
├── blockchain-guide.md # Blockchain technology guide
└── upcoming-features.md # Feature roadmap
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Issues** - Report bugs or request features in [GitHub Issues](https://github.com/your-username/isiza_pay/issues)
- **Documentation** - Check the `docs/` folder for detailed guides
- **Flutter Help** - [Official Flutter Documentation](https://docs.flutter.dev/)

---

**Built with ❤️ for the future of peer-to-peer payments**
