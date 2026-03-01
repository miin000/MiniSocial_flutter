// lib/screens/chat/chat_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../services/cloudinary_service.dart';
import 'group_info_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final ConversationModel conversation;
  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final CloudinaryService _cloudinary = CloudinaryService();
  final ImagePicker _picker = ImagePicker();

  MessageModel? _replyTo;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().fetchMessages(widget.conversation.id, refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final chatProvider = context.read<ChatProvider>();
      if (chatProvider.hasMoreMessages(widget.conversation.id) && !chatProvider.isLoadingMessages) {
        chatProvider.loadMoreMessages(widget.conversation.id);
      }
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendText() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _msgController.clear();

    setState(() => _isSending = true);
    await context.read<ChatProvider>().sendMessage(
      convId: widget.conversation.id,
      content: text,
      replyToId: _replyTo?.id,
    );
    setState(() {
      _isSending = false;
      _replyTo = null;
    });
  }

  Future<void> _sendImage() async {
    final files = await _picker.pickMultiImage(imageQuality: 80, maxWidth: 1200);
    if (files.isEmpty) return;

    setState(() => _isSending = true);
    try {
      List<String> urls = [];
      for (final f in files) {
        final url = await _cloudinary.uploadXFile(f);
        if (url != null) urls.add(url);
      }
      if (urls.isNotEmpty) {
        await context.read<ChatProvider>().sendMessage(
          convId: widget.conversation.id,
          content: '📷 Hình ảnh',
          messageType: 'image',
          mediaUrls: urls,
          replyToId: _replyTo?.id,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Lỗi upload: $e');
    }
    setState(() {
      _isSending = false;
      _replyTo = null;
    });
  }

  void _showMessageActions(MessageModel msg) {
    final authProvider = context.read<AuthProvider>();
    final isMe = msg.senderId == authProvider.user?.id;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.grey[300], borderRadius: BorderRadius.circular(2),
            )),
            const SizedBox(height: 8),
            if (!msg.isRecalled) ...[
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Trả lời'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _replyTo = msg);
                },
              ),
              if (msg.isText && msg.content != null)
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Sao chép'),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg.content!));
                    Navigator.pop(context);
                    Fluttertoast.showToast(msg: 'Đã sao chép');
                  },
                ),
              if (isMe && msg.isText)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Chỉnh sửa'),
                  onTap: () {
                    Navigator.pop(context);
                    _showEditDialog(msg);
                  },
                ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.undo, color: Colors.orange),
                  title: const Text('Thu hồi', style: TextStyle(color: Colors.orange)),
                  onTap: () async {
                    Navigator.pop(context);
                    await context.read<ChatProvider>().recallMessage(msg.id, widget.conversation.id);
                    Fluttertoast.showToast(msg: 'Đã thu hồi');
                  },
                ),
            ],
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Xóa phía mình', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await context.read<ChatProvider>().deleteMessage(msg.id, widget.conversation.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(MessageModel msg) {
    final editController = TextEditingController(text: msg.content);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chỉnh sửa tin nhắn'),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newContent = editController.text.trim();
              if (newContent.isNotEmpty && newContent != msg.content) {
                await context.read<ChatProvider>().editMessage(msg.id, widget.conversation.id, newContent);
                Fluttertoast.showToast(msg: 'Đã chỉnh sửa');
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.user?.id ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3b82f6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: GestureDetector(
          onTap: widget.conversation.type == 'group'
              ? () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => GroupInfoScreen(conversation: widget.conversation)))
              : null,
          child: Row(
            children: [
              _buildHeaderAvatar(),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.conversation.displayName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (widget.conversation.type == 'group' && widget.conversation.memberCount != null)
                      Text('${widget.conversation.memberCount} thành viên',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (widget.conversation.type == 'group')
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => GroupInfoScreen(conversation: widget.conversation),
              )),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Messages list ───────────────────────────────────
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                final messages = chatProvider.getMessages(widget.conversation.id);

                if (chatProvider.isLoadingMessages && messages.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (messages.isEmpty) {
                  return const Center(
                    child: Text('Chưa có tin nhắn\nHãy bắt đầu trò chuyện!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 15)),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true, // newest at bottom
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemCount: messages.length + (chatProvider.isLoadingMessages ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (chatProvider.isLoadingMessages && index == messages.length) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ));
                    }
                    final msg = messages[index];
                    final isMe = msg.senderId == currentUserId;
                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      onLongPress: () => _showMessageActions(msg),
                    );
                  },
                );
              },
            ),
          ),

          // ── Reply preview ───────────────────────────────────
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Container(width: 3, height: 30, color: const Color(0xFF3b82f6)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_replyTo!.senderName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF3b82f6))),
                        Text(_replyTo!.content ?? '📷 Hình ảnh',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() => _replyTo = null),
                  ),
                ],
              ),
            ),

          // ── Input area ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4, offset: const Offset(0, -1))],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image, color: Color(0xFF3b82f6)),
                    onPressed: _isSending ? null : _sendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _msgController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendText(),
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _isSending
                      ? const SizedBox(width: 40, height: 40, child: Padding(
                          padding: EdgeInsets.all(8),
                          child: CircularProgressIndicator(strokeWidth: 2)))
                      : IconButton(
                          icon: const Icon(Icons.send, color: Color(0xFF3b82f6)),
                          onPressed: _sendText,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAvatar() {
    final url = widget.conversation.displayAvatar;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(radius: 18, backgroundImage: CachedNetworkImageProvider(url));
    }
    return CircleAvatar(
      radius: 18,
      backgroundColor: Colors.white24,
      child: Icon(
        widget.conversation.type == 'group' ? Icons.group : Icons.person,
        color: Colors.white, size: 20,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Message bubble widget
// ════════════════════════════════════════════════════════════════════════════════

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // System messages → centered
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(message.content ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildSenderAvatar(),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: message.isRecalled
                      ? Colors.grey.shade100
                      : isMe
                          ? const Color(0xFF3b82f6)
                          : Colors.grey.shade100,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Sender name (group chat, not me)
                    if (!isMe && message.senderInfo != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(message.senderName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          )),
                      ),

                    // Reply preview
                    if (message.replyToInfo != null)
                      Container(
                        padding: const EdgeInsets.all(6),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: isMe ? const Color.fromRGBO(255, 255, 255, 0.15) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                          border: Border(
                            left: BorderSide(width: 2, color: isMe ? Colors.white70 : const Color(0xFF3b82f6)),
                          ),
                        ),
                        child: Text(
                          message.replyToInfo!['content'] ?? '📷 Hình ảnh',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isMe ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ),

                    // Content
                    if (message.isRecalled)
                      Text('Tin nhắn đã bị thu hồi',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[500],
                          fontSize: 13,
                        ))
                    else if (message.isImage && message.mediaUrls.isNotEmpty)
                      _buildImageContent()
                    else if (message.isSharePost)
                      _buildSharedPost()
                    else
                      Text(
                        message.content ?? '',
                        style: TextStyle(
                          color: isMe ? Colors.white : Colors.black87,
                          fontSize: 14,
                        ),
                      ),

                    // Time + edited
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isEdited)
                          Text('đã sửa · ',
                            style: TextStyle(
                              fontSize: 10,
                              color: isMe ? Colors.white60 : Colors.grey,
                            )),
                        Text(
                          _formatMsgTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe ? Colors.white60 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderAvatar() {
    final url = message.senderAvatar;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(radius: 14, backgroundImage: CachedNetworkImageProvider(url));
    }
    return const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 14));
  }

  Widget _buildImageContent() {
    if (message.mediaUrls.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: message.mediaUrls[0],
          width: 200,
          fit: BoxFit.cover,
          placeholder: (_, __) => const SizedBox(
            width: 200, height: 150,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: message.mediaUrls.map((url) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: url, width: 120, height: 120, fit: BoxFit.cover,
        ),
      )).toList(),
    );
  }

  Widget _buildSharedPost() {
    final info = message.sharedPostInfo;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? const Color.fromRGBO(255, 255, 255, 0.15) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.article_outlined, size: 14,
                color: isMe ? Colors.white70 : const Color(0xFF3b82f6)),
              const SizedBox(width: 4),
              Text('Bài viết được chia sẻ',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                  color: isMe ? Colors.white70 : const Color(0xFF3b82f6))),
            ],
          ),
          const SizedBox(height: 6),
          // Author info
          if (info != null && info['user_name'] != null)
            Row(
              children: [
                if (info['user_avatar'] != null && (info['user_avatar'] as String).isNotEmpty)
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: CachedNetworkImageProvider(info['user_avatar']),
                  )
                else
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: isMe ? Colors.white24 : Colors.grey.shade300,
                    child: Icon(Icons.person, size: 12,
                      color: isMe ? Colors.white70 : Colors.grey),
                  ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    info['user_name'] ?? '',
                    style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          // Post content
          if (info != null && info['content'] != null &&
              (info['content'] as String).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              info['content'],
              maxLines: 3, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13,
                color: isMe ? Colors.white : Colors.black87),
            ),
          ],
          // Post image preview
          if (info != null &&
              info['media_urls'] != null &&
              (info['media_urls'] as List).isNotEmpty) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: (info['media_urls'] as List).first.toString(),
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 120,
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
              ),
            ),
            if ((info['media_urls'] as List).length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '+${(info['media_urls'] as List).length - 1} ảnh khác',
                  style: TextStyle(fontSize: 10,
                    color: isMe ? Colors.white60 : Colors.grey),
                ),
              ),
          ],
          // Tags
          if (info != null &&
              info['tags'] != null &&
              (info['tags'] as List).isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: (info['tags'] as List).map<Widget>((tag) => Text(
                '#$tag',
                style: TextStyle(
                  fontSize: 10,
                  color: isMe ? Colors.white70 : const Color(0xFF3b82f6),
                  fontWeight: FontWeight.w500,
                ),
              )).toList(),
            ),
          ],
          // Stats
          if (info != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.favorite, size: 12,
                  color: isMe ? Colors.white60 : Colors.grey),
                const SizedBox(width: 2),
                Text('${info['likes_count'] ?? 0}',
                  style: TextStyle(fontSize: 10,
                    color: isMe ? Colors.white60 : Colors.grey)),
                const SizedBox(width: 8),
                Icon(Icons.comment, size: 12,
                  color: isMe ? Colors.white60 : Colors.grey),
                const SizedBox(width: 2),
                Text('${info['comments_count'] ?? 0}',
                  style: TextStyle(fontSize: 10,
                    color: isMe ? Colors.white60 : Colors.grey)),
              ],
            ),
          ],
          // Caption from sender
          if (message.content != null && message.content!.isNotEmpty) ...[
            const Divider(height: 10),
            Text(message.content!,
              maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12,
                color: isMe ? Colors.white : Colors.black87,
                fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  String _formatMsgTime(DateTime? time) {
    if (time == null) return '';
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
