/// LONE LINK — About Screen
///
/// Shows app info, protocol details, and academic project context.
library;

import 'package:flutter/material.dart';
import 'package:lone_link/core/constants/app_constants.dart';
import 'package:lone_link/presentation/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Logo and name
          Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [LoneLinkColors.primary, LoneLinkColors.primaryDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: LoneLinkColors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.link, size: 40, color: Colors.black),
                ),
                const SizedBox(height: 16),
                const Text(
                  'LONE LINK',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version $kAppVersion',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Description
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: LoneLinkColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lone Link is a hybrid decentralized messaging application '
                    'that uses Bluetooth Low Energy (BLE) mesh networking and '
                    'Internet transport to deliver messages between devices.\n\n'
                    'Messages can be sent directly between nearby devices, '
                    'relayed through multi-hop BLE mesh, bridged through '
                    'Internet-connected nodes, or queued for later delivery.\n\n'
                    'All messages are end-to-end encrypted. Relay nodes cannot '
                    'read message content.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Protocol
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Protocol',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: LoneLinkColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow('Protocol Version', '$kProtocolVersion'),
                  _InfoRow('Encryption', 'AES-256-GCM'),
                  _InfoRow('Key Exchange', 'X25519 (ECDH)'),
                  _InfoRow('Signatures', 'Ed25519'),
                  _InfoRow('Max TTL', '$kDefaultMessageTtl hops'),
                  _InfoRow('Max Payload', '${kMaxPacketPayloadSize ~/ 1024} KB'),
                  _InfoRow('Deduplication', 'Message ID cache'),
                  _InfoRow('Sync', 'Merkle-tree based'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Architecture features
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Features',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: LoneLinkColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _FeatureItem('Direct BLE messaging'),
                  _FeatureItem('Multi-hop BLE mesh relay'),
                  _FeatureItem('Store-and-forward queuing'),
                  _FeatureItem('Internet / WebSocket transport'),
                  _FeatureItem('Automatic BLE-to-Internet bridging'),
                  _FeatureItem('Message deduplication'),
                  _FeatureItem('TTL-based routing'),
                  _FeatureItem('End-to-end encryption'),
                  _FeatureItem('Replay protection'),
                  _FeatureItem('Merkle-tree synchronization'),
                  _FeatureItem('Offline-first persistence'),
                  _FeatureItem('Delivery acknowledgements'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Academic context
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic Context',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: LoneLinkColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This application was developed as a capstone project to '
                    'demonstrate decentralized communication concepts including '
                    'BLE mesh networking, hybrid transport routing, cryptographic '
                    'identity management, and resilient message delivery.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: LoneLinkColors.darkTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  const _FeatureItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: LoneLinkColors.primary),
          const SizedBox(width: 10),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
