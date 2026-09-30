/// LONE LINK — Chat Screen
///
/// 1:1 chat interface showing messages with delivery status,
/// transport indicators, and timestamps.
/// Text input with send button that will connect to real message service.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;

import 'package:lone_link/presentation/theme/app_theme.dart';
import 'package:lone_link/presentation/providers/providers.dart';
import 'package:lone_link/presentation/widgets/shared_widgets.dart';
import 'package:lone_link/domain/entities/enums.dart';
import 'package:lone_link/storage/database/database.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String conversationId;

  const ChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      // TODO(Phase 2): Connect to MessageService.sendMessage()
      // This will:
      // 1. Create a Message entity with a crypto-secure ID
      // 2. Create a MessageEnvelope
      // 3. Encrypt the payload (Phase 8)
      // 4. Enqueue for delivery via the best available transport
      // 5. Update the conversation's lastMessagePreview
      //
      // For Phase 1, we save directly to the database to validate the pipeline.
      final db = ref.read(databaseProvider);

      final messageId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);

      await db.into(db.messages).insert(
        MessagesCompanion.insert(
          id: messageId,
          conversationId: widget.conversationId,
          senderId: '', // TODO: Use local identity ID
          recipientId: '', // TODO: Get from conversation
          isOutgoing: true,
          createdAt: DateTime.now(),
          content: drift.Value(text),
          status: const drift.Value('queued'),
        ),
      );

      // Update conversation preview
      await (db.update(db.conversations)
            ..where((t) => t.id.equals(widget.conversationId)))
          .write(ConversationsCompanion(
            lastMessagePreview: drift.Value(text),
            lastMessageAt: drift.Value(DateTime.now()),
          ));

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesStreamProvider(widget.conversationId));
    final connectivity = ref.watch(connectivityStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: _buildAppBarTitle(),
        actions: [
          // Connection indicator
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ConnectionDot(
              state: PeerConnectionState.disconnected, // TODO: real peer state
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              // TODO: Handle menu actions
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'details', child: Text('Message Details')),
              const PopupMenuItem(value: 'sync', child: Text('Sync Status')),
              const PopupMenuItem(value: 'clear', child: Text('Clear Chat')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          ConnectivityBanner(state: connectivity),

          // Messages list
          Expanded(
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.chat_outlined,
                    title: 'No messages yet',
                    subtitle: 'Send a message to start the conversation.',
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _MessageBubble(message: msg);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildAppBarTitle() {
    // TODO: Pull real peer name from conversation
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Peer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        Text(
          'Disconnected', // TODO: real status
          style: TextStyle(fontSize: 12, color: LoneLinkColors.darkTextTertiary),
        ),
      ],
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: LoneLinkColors.darkSurface,
        border: Border(
          top: BorderSide(
            color: LoneLinkColors.darkDivider.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: LoneLinkColors.darkTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Message',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: LoneLinkColors.darkSurfaceElevated,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          Container(
            decoration: const BoxDecoration(
              color: LoneLinkColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.black),
                      ),
                    )
                  : const Icon(Icons.send, size: 20),
              color: Colors.black,
              onPressed: _isSending ? null : _sendMessage,
              tooltip: 'Send message',
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Message Bubble
// ─────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final dynamic message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final bool isOutgoing = message.isOutgoing as bool? ?? false;
    final String content = message.content as String? ?? '';
    final DateTime createdAt = message.createdAt as DateTime? ?? DateTime.now();
    final String statusStr = message.status as String? ?? 'created';
    final String transportStr = message.transportType as String? ?? 'unknown';

    final status = MessageStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => MessageStatus.created,
    );
    final transport = TransportType.values.firstWhere(
      (t) => t.name == transportStr,
      orElse: () => TransportType.unknown,
    );

    return Align(
      alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isOutgoing
              ? LoneLinkColors.outgoingBubbleDark
              : LoneLinkColors.incomingBubbleDark,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isOutgoing ? 18 : 4),
            bottomRight: Radius.circular(isOutgoing ? 4 : 18),
          ),
          border: Border.all(
            color: isOutgoing
                ? LoneLinkColors.primary.withValues(alpha: 0.15)
                : LoneLinkColors.darkDivider.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment:
              isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message text
            Text(
              content,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                height: 1.35,
                color: LoneLinkColors.darkTextPrimary,
              ),
            ),
            const SizedBox(height: 4),

            // Status row: time + transport + delivery status
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Timestamp
                Text(
                  _formatTime(createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: LoneLinkColors.darkTextTertiary,
                  ),
                ),

                // Transport badge (only for sent messages)
                if (isOutgoing && transport != TransportType.unknown) ...[
                  const SizedBox(width: 6),
                  TransportBadge(transport: transport, fontSize: 9),
                ],

                // Delivery status (only for outgoing)
                if (isOutgoing) ...[
                  const SizedBox(width: 4),
                  MessageStatusIndicator(status: status, size: 14),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
