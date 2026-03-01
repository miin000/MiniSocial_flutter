// lib/providers/chat_provider.dart

import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../models/conversation_model.dart';
import '../models/message_model.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _service = ChatService();

  // ── State ────────────────────────────────────────────────────────────────
  List<ConversationModel> _conversations = [];
  Map<String, List<MessageModel>> _messages = {}; // convId → messages
  Map<String, List<ParticipantModel>> _members = {}; // convId → members
  bool _isLoading = false;
  bool _isLoadingMessages = false;
  String? _error;
  Map<String, int> _currentPage = {};
  Map<String, bool> _hasMore = {};

  // ── Getters ──────────────────────────────────────────────────────────────
  List<ConversationModel> get conversations => _conversations;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get error => _error;

  List<MessageModel> getMessages(String convId) => _messages[convId] ?? [];
  List<ParticipantModel> getMembers(String convId) => _members[convId] ?? [];
  bool hasMoreMessages(String convId) => _hasMore[convId] ?? true;

  int get totalUnread {
    int count = 0;
    for (final c in _conversations) {
      count += c.unreadCount;
    }
    return count;
  }

  // ── Conversations ────────────────────────────────────────────────────────

  Future<void> fetchConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _service.getConversations();
    if (result['success'] == true) {
      final data = result['data'];
      if (data is List) {
        _conversations = data.map((e) => ConversationModel.fromJson(
            e is Map<String, dynamic> ? e : {})).toList();
        // Sắp xếp theo last_message_at mới nhất
        _conversations.sort((a, b) {
          final aTime = a.lastMessageAt ?? a.createdAt ?? DateTime(2000);
          final bTime = b.lastMessageAt ?? b.createdAt ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });
      }
    } else {
      _error = result['message'] ?? 'Lỗi tải danh sách chat';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<ConversationModel?> createPrivateChat(String friendId) async {
    final result = await _service.createPrivateChat(friendId);
    if (result['success'] == true && result['data'] != null) {
      final conv = ConversationModel.fromJson(
          result['data'] is Map<String, dynamic> ? result['data'] : {});
      _conversations.removeWhere((c) => c.id == conv.id);
      _conversations.insert(0, conv);
      notifyListeners();
      return conv;
    }
    _error = result['message'] ?? 'Không thể tạo cuộc trò chuyện';
    notifyListeners();
    return null;
  }

  Future<ConversationModel?> createGroupChat({
    required String name,
    required List<String> participantIds,
    String? avatarUrl,
  }) async {
    final result = await _service.createGroupChat(
      name: name,
      participantIds: participantIds,
      avatarUrl: avatarUrl,
    );
    if (result['success'] == true && result['data'] != null) {
      final conv = ConversationModel.fromJson(
          result['data'] is Map<String, dynamic> ? result['data'] : {});
      _conversations.insert(0, conv);
      notifyListeners();
      return conv;
    }
    _error = result['message'] ?? 'Không thể tạo nhóm';
    notifyListeners();
    return null;
  }

  Future<bool> updateGroup(String convId, {String? name, String? avatarUrl}) async {
    final result = await _service.updateGroup(convId, name: name, avatarUrl: avatarUrl);
    if (result['success'] == true) {
      await fetchConversations();
      return true;
    }
    return false;
  }

  Future<bool> deleteConversation(String convId) async {
    final result = await _service.deleteConversation(convId);
    if (result['success'] == true) {
      _conversations.removeWhere((c) => c.id == convId);
      _messages.remove(convId);
      _members.remove(convId);
      notifyListeners();
      return true;
    }
    return false;
  }

  // ── Messages ─────────────────────────────────────────────────────────────

  Future<void> fetchMessages(String convId, {bool refresh = false}) async {
    if (refresh) {
      _currentPage[convId] = 1;
      _hasMore[convId] = true;
      _messages[convId] = [];
    }

    final page = _currentPage[convId] ?? 1;
    if (!(_hasMore[convId] ?? true)) return;

    _isLoadingMessages = true;
    notifyListeners();

    final result = await _service.getMessages(convId, page: page, limit: 30);
    if (result['success'] == true && result['data'] != null) {
      final data = result['data'];
      List<dynamic> msgList = [];
      int total = 0;

      if (data is Map) {
        msgList = data['messages'] ?? [];
        total = data['total'] ?? 0;
      } else if (data is List) {
        msgList = data;
      }

      final newMessages = msgList
          .map((e) => MessageModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();

      if (refresh || page == 1) {
        _messages[convId] = newMessages;
      } else {
        _messages[convId] = [...(_messages[convId] ?? []), ...newMessages];
      }

      _currentPage[convId] = page + 1;
      _hasMore[convId] = (_messages[convId]?.length ?? 0) < total;

      // Mark as read
      _service.markAsRead(convId);
      // Update local unread
      final idx = _conversations.indexWhere((c) => c.id == convId);
      if (idx >= 0) {
        _conversations[idx] = _conversations[idx].copyWith(unreadCount: 0);
      }
    }

    _isLoadingMessages = false;
    notifyListeners();
  }

  Future<void> loadMoreMessages(String convId) async {
    await fetchMessages(convId);
  }

  Future<bool> sendMessage({
    required String convId,
    String? content,
    String? messageType,
    List<String>? mediaUrls,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? replyToId,
  }) async {
    final result = await _service.sendMessage(
      convId: convId,
      content: content,
      messageType: messageType,
      mediaUrls: mediaUrls,
      fileUrl: fileUrl,
      fileName: fileName,
      fileSize: fileSize,
      replyToId: replyToId,
    );

    if (result['success'] == true && result['data'] != null) {
      final msg = MessageModel.fromJson(
          result['data'] is Map<String, dynamic> ? result['data'] : {});
      // Thêm tin nhắn mới vào đầu danh sách (latest first)
      _messages[convId] = [msg, ...(_messages[convId] ?? [])];

      // Cập nhật conversation's last message
      final idx = _conversations.indexWhere((c) => c.id == convId);
      if (idx >= 0) {
        _conversations[idx] = _conversations[idx].copyWith(
          lastMessageContent: content ?? (messageType == 'image' ? '📷 Hình ảnh' : '📎 File'),
          lastMessageAt: DateTime.now(),
        );
        // Đưa conversation lên đầu
        final conv = _conversations.removeAt(idx);
        _conversations.insert(0, conv);
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> sharePost({
    required String convId,
    required String postId,
    String? content,
  }) async {
    final result = await _service.sharePost(
      convId: convId,
      postId: postId,
      content: content,
    );

    if (result['success'] == true) {
      await fetchMessages(convId, refresh: true);
      return true;
    }
    return false;
  }

  Future<bool> editMessage(String messageId, String convId, String content) async {
    final result = await _service.editMessage(messageId, content);
    if (result['success'] == true) {
      // Cập nhật local
      final msgs = _messages[convId] ?? [];
      final idx = msgs.indexWhere((m) => m.id == messageId);
      if (idx >= 0) {
        _messages[convId]![idx] = msgs[idx].copyWith(
          content: content,
          isEdited: true,
        );
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> recallMessage(String messageId, String convId) async {
    final result = await _service.recallMessage(messageId);
    if (result['success'] == true) {
      final msgs = _messages[convId] ?? [];
      final idx = msgs.indexWhere((m) => m.id == messageId);
      if (idx >= 0) {
        _messages[convId]![idx] = msgs[idx].copyWith(
          isRecalled: true,
          content: '',
        );
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  Future<bool> deleteMessage(String messageId, String convId) async {
    final result = await _service.deleteMessage(messageId);
    if (result['success'] == true) {
      _messages[convId]?.removeWhere((m) => m.id == messageId);
      notifyListeners();
      return true;
    }
    return false;
  }

  // ── Participants ──────────────────────────────────────────────────────────

  Future<void> fetchMembers(String convId) async {
    final result = await _service.getMembers(convId);
    if (result['success'] == true && result['data'] is List) {
      _members[convId] = (result['data'] as List)
          .map((e) => ParticipantModel.fromJson(e is Map<String, dynamic> ? e : {}))
          .toList();
      notifyListeners();
    }
  }

  Future<bool> addMember(String convId, String userId) async {
    final result = await _service.addMember(convId, userId);
    if (result['success'] == true) {
      await fetchMembers(convId);
      return true;
    }
    return false;
  }

  Future<bool> removeMember(String convId, String userId) async {
    final result = await _service.removeMember(convId, userId);
    if (result['success'] == true) {
      _members[convId]?.removeWhere((m) => m.userId == userId);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> leaveGroup(String convId) async {
    final result = await _service.leaveGroup(convId);
    if (result['success'] == true) {
      _conversations.removeWhere((c) => c.id == convId);
      _messages.remove(convId);
      _members.remove(convId);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> updateRole(String convId, String userId, String role) async {
    final result = await _service.updateRole(convId, userId, role);
    if (result['success'] == true) {
      await fetchMembers(convId);
      return true;
    }
    return false;
  }

  Future<bool> transferLeadership(String convId, String userId) async {
    final result = await _service.transferLeadership(convId, userId);
    if (result['success'] == true) {
      await fetchMembers(convId);
      return true;
    }
    return false;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void clearAll() {
    _conversations = [];
    _messages = {};
    _members = {};
    _currentPage = {};
    _hasMore = {};
    _error = null;
    notifyListeners();
  }
}
