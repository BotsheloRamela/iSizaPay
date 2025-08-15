import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/p2p_service.dart';
import '../screens/payment_send_screen.dart';

class P2PConnectionScreen extends StatefulWidget {
  final String deviceId;
  final String deviceName;

  const P2PConnectionScreen({
    super.key,
    required this.deviceId,
    required this.deviceName,
  });

  @override
  State<P2PConnectionScreen> createState() => _P2PConnectionScreenState();
}

class _P2PConnectionScreenState extends State<P2PConnectionScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  late P2PService _p2pService;

  @override
  void initState() {
    super.initState();
    _p2pService = Provider.of<P2PService>(context, listen: false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.deviceName),
            Consumer<P2PService>(
              builder: (context, service, child) {
                final isConnected = service.connectedDevices.containsKey(widget.deviceId);
                return Text(
                  isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    fontSize: 12,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<P2PService>(
            builder: (context, service, child) {
              final isConnected = service.connectedDevices.containsKey(widget.deviceId);
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isConnected)
                    IconButton(
                      icon: const Icon(Icons.payments, color: Colors.blue),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => PaymentSendScreen(
                              recipientDeviceId: widget.deviceId,
                              recipientDeviceName: widget.deviceName,
                            ),
                          ),
                        );
                      },
                      tooltip: 'Send Payment',
                    ),
                  IconButton(
                    icon: Icon(
                      isConnected ? Icons.link_off : Icons.link,
                      color: isConnected ? Colors.red : Colors.green,
                    ),
                    onPressed: () {
                      if (isConnected) {
                        _showDisconnectDialog();
                      } else {
                        _p2pService.connectToDevice(widget.deviceId);
                      }
                    },
                    tooltip: isConnected ? 'Disconnect' : 'Connect',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<P2PService>(
        builder: (context, service, child) {
          final isConnected = service.connectedDevices.containsKey(widget.deviceId);
          
          return Column(
            children: [
              _buildConnectionStatus(service, isConnected),
              Expanded(
                child: _buildChatArea(isConnected),
              ),
              _buildMessageInput(isConnected),
            ],
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus(P2PService service, bool isConnected) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isConnected) {
      statusColor = Colors.green;
      statusIcon = Icons.cloud_done;
      statusText = 'Connected to ${widget.deviceName}';
    } else {
      switch (service.status) {
        case P2PConnectionStatus.connecting:
          statusColor = Colors.orange;
          statusIcon = Icons.sync;
          statusText = 'Connecting to ${widget.deviceName}...';
          break;
        case P2PConnectionStatus.error:
          statusColor = Colors.red;
          statusIcon = Icons.error;
          statusText = 'Connection failed: ${service.errorMessage ?? "Unknown error"}';
          break;
        default:
          statusColor = Colors.grey;
          statusIcon = Icons.cloud_off;
          statusText = 'Not connected to ${widget.deviceName}';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      color: statusColor.withOpacity(0.1),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (service.status == P2PConnectionStatus.connecting)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatArea(bool isConnected) {
    if (!isConnected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Not Connected',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to ${widget.deviceName} to start messaging',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _p2pService.connectToDevice(widget.deviceId),
              icon: const Icon(Icons.link),
              label: const Text('Connect'),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send a message to start the conversation',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderId == _p2pService.currentDeviceId;
    
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color: isMe ? Colors.white70 : Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isConnected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: isConnected,
              decoration: InputDecoration(
                hintText: isConnected 
                    ? 'Type a message...' 
                    : 'Connect to send messages',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: isConnected ? (_) => _sendMessage() : null,
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: isConnected && _messageController.text.trim().isNotEmpty
                ? _sendMessage
                : null,
            child: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatMessage = ChatMessage(
      content: message,
      senderId: _p2pService.currentDeviceId ?? 'unknown',
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(chatMessage);
    });

    _p2pService.sendMessage(widget.deviceId, message);
    _messageController.clear();
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Device'),
        content: Text('Are you sure you want to disconnect from ${widget.deviceName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _p2pService.disconnectFromDevice(widget.deviceId);
              Navigator.of(context).pop(); // Go back to discovery screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (difference.inHours > 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
}

class ChatMessage {
  final String content;
  final String senderId;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.senderId,
    required this.timestamp,
  });
}