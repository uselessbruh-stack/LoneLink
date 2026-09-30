/// LONE LINK — Conversations Screen
///
/// Lists all conversations ordered by last message time.
/// Shows peer name, last message preview, time, unread count,
/// and transport indicator.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:lone_link/presentation/router.dart';
import 'package:lone_link/presentation/theme/app_theme.dart';
import 'package:lone_link/presentation/providers/providers.dart';
import 'package:lone_link/presentation/widgets/shared_widgets.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Diagnostics',
            onPressed: () => context.push(AppRoutes.diagnostics),
          ),
        ],
      ),
      body: conversationsAsync.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.chat_bubble_outline,
              title: 'No conversations yet',
              subtitle: 'Discover nearby peers to start messaging.\n'
                  'Messages are sent directly between devices.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => const Divider(indent: 76),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return _ConversationTile(conversation: conv);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text('Error loading conversations: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'new_chat',
        onPressed: () {
          // Navigate to nearby peers to start a new conversation
          context.go(AppRoutes.nearby);
        },
        tooltip: 'New conversation',
        child: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final dynamic conversation;

  const _ConversationTile({required this.conversation});

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    }
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.month}/${dateTime.day}';
  }

  @override
  Widget build(BuildContext context) {
    // conversation is a Drift-generated data class from watchAllConversations
    final String peerName = conversation.peerDisplayName ?? 'Unknown';
    final String? preview = conversation.lastMessagePreview;
    final DateTime? lastTime = conversation.lastMessageAt;
    final int unread = conversation.unreadCount ?? 0;
    final String convId = conversation.id;

    return ListTile(
      onTap: () => context.push(AppRoutes.chatPath(convId)),
      leading: _buildAvatar(peerName),
      title: Row(
        children: [
          Expanded(
            child: Text(
              peerName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            _formatTime(lastTime),
            style: TextStyle(
              fontSize: 12,
              color: unread > 0
                  ? LoneLinkColors.primary
                  : LoneLinkColors.darkTextTertiary,
              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              preview ?? 'No messages yet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unread > 0
                    ? LoneLinkColors.darkTextSecondary
                    : LoneLinkColors.darkTextTertiary,
                fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ),
          if (unread > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: LoneLinkColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    // Generate a consistent color from name
    final hue = (name.hashCode % 360).abs().toDouble();
    final color = HSLColor.fromAHSL(1.0, hue, 0.5, 0.35).toColor();

    return CircleAvatar(
      radius: 24,
      backgroundColor: color,
      child: Text(
        initial,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
