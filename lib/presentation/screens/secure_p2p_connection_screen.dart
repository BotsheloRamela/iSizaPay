import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isiza_pay/services/security_handshake_service.dart';
import 'package:isiza_pay/services/device_identity_service.dart';
import 'package:isiza_pay/presentation/screens/security_verification_screen.dart';

class SecureP2PConnectionScreen extends ConsumerStatefulWidget {
  final String deviceId;
  final String deviceName;
  final String remotePublicKey;

  const SecureP2PConnectionScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
    required this.remotePublicKey,
  });

  @override
  ConsumerState<SecureP2PConnectionScreen> createState() => _SecureP2PConnectionScreenState();
}

class _SecureP2PConnectionScreenState extends ConsumerState<SecureP2PConnectionScreen> {
  late SecurityHandshakeService _handshakeService;
  HandshakeSession? _currentSession;
  final List<SecureMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final deviceIdentity = ref.read(deviceIdentityServiceProvider);
    _handshakeService = SecurityHandshakeService(deviceIdentity);
    _handshakeService.onSessionUpdated = _handleSessionUpdate;
    _handshakeService.onSecureMessageReceived = _handleSecureMessage;
    _showVerificationModeSelection();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _showVerificationModeSelection() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Choose Verification Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How would you like to verify the connection to ${widget.deviceName}?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            _buildVerificationOption(
              icon: Icons.remove_red_eye,
              title: 'Visual Verification',
              description: 'Compare codes displayed on both devices',
              onTap: () {
                Navigator.of(context).pop();
                _initiateHandshake(VerificationMode.visual);
              },
            ),
            const SizedBox(height: 12),
            _buildVerificationOption(
              icon: Icons.pin,
              title: 'PIN Entry',
              description: 'Enter PIN shown on other device',
              onTap: () {
                Navigator.of(context).pop();
                _initiateHandshake(VerificationMode.pin);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.blue.shade600),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateHandshake(VerificationMode mode) async {
    try {
      final session = await _handshakeService.initiateHandshake(
        deviceId: widget.deviceId,
        deviceName: widget.deviceName,
        remotePublicKeyStr: widget.remotePublicKey,
        verificationMode: mode,
      );
      
      setState(() {
        _currentSession = session;
      });

      _showVerificationScreen(session);
    } catch (e) {
      _showError('Failed to initiate handshake: $e');
    }
  }

  void _showVerificationScreen(HandshakeSession session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SecurityVerificationScreen(
          session: session,
          onVerificationComplete: _handleVerificationComplete,
        ),
      ),
    );
  }

  Future<void> _handleVerificationComplete(bool verified, {String? enteredPin}) async {
    Navigator.of(context).pop(); // Close verification screen
    
    if (_currentSession == null) return;

    final success = await _handshakeService.confirmVerification(
      _currentSession!.sessionId,
      enteredPin: enteredPin,
    );

    if (!success) {
      _showError('Verification failed. Please try again.');
    }
  }

  void _handleSessionUpdate(String sessionId, HandshakeSession session) {
    if (session.sessionId == _currentSession?.sessionId) {
      setState(() {
        _currentSession = session;
      });

      if (session.status == HandshakeStatus.secured) {
        _showSuccessMessage('Connection secured! You can now transact safely.');
      } else if (session.status == HandshakeStatus.failed) {
        _showError('Security verification failed.');
      }
    }
  }

  void _handleSecureMessage(String sessionId, SecureMessage message) {
    if (sessionId == _currentSession?.sessionId) {
      setState(() {
        _messages.add(message);
      });
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(error)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Connection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_currentSession != null)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: _buildStatusIndicator(),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildConnectionInfo(),
          if (_currentSession?.status == HandshakeStatus.secured) ...[
            Expanded(child: _buildSecureMessaging()),
            _buildMessageInput(),
          ] else
            Expanded(child: _buildWaitingView()),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (_currentSession == null) return const SizedBox();

    Color color;
    IconData icon;
    String tooltip;

    switch (_currentSession!.status) {
      case HandshakeStatus.waitingForVerification:
        color = Colors.orange;
        icon = Icons.security;
        tooltip = 'Waiting for verification';
        break;
      case HandshakeStatus.verifying:
        color = Colors.blue;
        icon = Icons.sync;
        tooltip = 'Verifying connection';
        break;
      case HandshakeStatus.secured:
        color = Colors.green;
        icon = Icons.verified_user;
        tooltip = 'Connection secured';
        break;
      case HandshakeStatus.failed:
        color = Colors.red;
        icon = Icons.error;
        tooltip = 'Security verification failed';
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
        tooltip = 'Unknown status';
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildConnectionInfo() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: Icon(Icons.devices, color: Colors.blue.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.deviceName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Device ID: ${widget.deviceId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Establishing secure connection...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please complete the verification process',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecureMessaging() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(SecureMessage message) {
    final isOutgoing = message.type == 'outgoing';
    
    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isOutgoing ? Colors.blue.shade500 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.data['content'] ?? '',
              style: TextStyle(
                color: isOutgoing ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified,
                  size: 12,
                  color: isOutgoing ? Colors.white70 : Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    color: isOutgoing ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a secure message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentSession == null) {
      return;
    }

    try {
      final message = await _handshakeService.createSecureMessage(
        sessionId: _currentSession!.sessionId,
        type: 'outgoing',
        data: {'content': _messageController.text.trim()},
      );

      setState(() {
        _messages.add(message);
        _messageController.clear();
      });
    } catch (e) {
      _showError('Failed to send message: $e');
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

final deviceIdentityServiceProvider = Provider<DeviceIdentityService>((ref) {
  return DeviceIdentityService();
});