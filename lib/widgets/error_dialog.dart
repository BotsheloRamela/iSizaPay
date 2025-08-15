import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const ErrorDialog({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade600),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Would you like to retry?',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (onRetry != null)
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry!();
            },
            child: const Text('Retry'),
          ),
      ],
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(
        title: title,
        message: message,
        onRetry: onRetry,
      ),
    );
  }
}

class PermissionDeniedDialog extends StatelessWidget {
  final List<String> permissions;

  const PermissionDeniedDialog({
    super.key,
    required this.permissions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning, color: Colors.orange),
          SizedBox(width: 8),
          Text('Permissions Required'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('The following permissions are required for P2P functionality:'),
          const SizedBox(height: 12),
          ...permissions.map((permission) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.circle, size: 6),
                    const SizedBox(width: 8),
                    Expanded(child: Text(permission)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          const Text(
            'Please grant these permissions in your device settings to use P2P features.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // You could implement opening app settings here
          },
          child: const Text('Open Settings'),
        ),
      ],
    );
  }

  static void show(BuildContext context, List<String> permissions) {
    showDialog(
      context: context,
      builder: (context) => PermissionDeniedDialog(permissions: permissions),
    );
  }
}

class PermissionGuideDialog extends StatelessWidget {
  const PermissionGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info, color: Colors.blue),
          SizedBox(width: 8),
          Text('P2P Permissions Guide'),
        ],
      ),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'To use P2P features, the following permissions are required:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 16),
            _PermissionItem(
              icon: Icons.location_on,
              title: 'Location Access',
              description: 'Required for device discovery via Bluetooth and WiFi',
            ),
            _PermissionItem(
              icon: Icons.bluetooth,
              title: 'Bluetooth',
              description: 'For discovering and connecting to nearby devices',
            ),
            _PermissionItem(
              icon: Icons.wifi,
              title: 'WiFi & Network',
              description: 'For WiFi-based peer connections',
            ),
            SizedBox(height: 16),
            Text(
              'Note: These permissions are only used for peer-to-peer connectivity and device discovery. No personal data is collected.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Request Permissions'),
        ),
      ],
    );
  }

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => const PermissionGuideDialog(),
    );
    return result ?? false;
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
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
        ],
      ),
    );
  }
}