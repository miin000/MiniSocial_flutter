import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';
import '../services/post_service.dart';
import '../services/api_service.dart';

class PostProvider with ChangeNotifier {
  final PostService _postService = PostService(ApiService().dio);

  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  // Load posts
  Future<void> loadPosts({
    bool refresh = false,
    String? userId,           // userId của người đăng bài (nếu muốn lấy bài của người khác)
    bool onlyMyPosts = false, // <-- Thêm tham số mới: true = chỉ lấy bài của user đang đăng nhập
  }) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _posts = [];
    }

    if (_isLoading || !_hasMore) return;

    try {
      await ApiService().loadToken();
      if (!ApiService().hasToken) {
        _isLoading = false;
        _error = 'Not authenticated';
        notifyListeners();
        return;
      }
    } catch (_) {
      _isLoading = false;
      _error = 'Not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Nếu onlyMyPosts = true → gọi endpoint lấy bài của chính user đăng nhập
      // Nếu không → gọi endpoint feed chung (có thể lọc theo userId nếu cần)
      final result = await _postService.getPosts(
        page: _currentPage,
        limit: 20,
        userId: onlyMyPosts ? null : userId,           // nếu onlyMyPosts thì backend sẽ tự hiểu lấy của user hiện tại
        onlyMyPosts: onlyMyPosts,                      // truyền thêm flag này xuống service
      );

      final List<Post> newPosts = result['posts'] as List<Post>;

      if (refresh) {
        _posts = newPosts;
      } else {
        _posts.addAll(newPosts);
      }

      _hasMore = newPosts.length >= 20;
      if (_hasMore) _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Clear posts and reset paging (useful on logout)
  void clearAll() {
    _posts = [];
    _isLoading = false;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  // Create post
  Future<Post?> createPost({
    required String userId,
    String? content,
    List<String>? mediaUrls,
    String? groupId,
    String? visibility,
  }) async {
    try {
      final newPost = await _postService.createPost(
        userId: userId,
        content: content,
        mediaUrls: mediaUrls,
        groupId: groupId,
        visibility: visibility,
      );

      // Only add to the main feed when the post is NOT created inside a group
      if (groupId == null) {
        _posts.insert(0, newPost);
        notifyListeners();
      }

      return newPost;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Delete post
  Future<bool> deletePost(String postId) async {
    try {
      await _postService.deletePost(postId);
      _posts.removeWhere((post) => post.id == postId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle like
  Future<void> toggleLike(String postId, String userId) async {
    try {
      // Optimistic update
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        final isLiked = post.isLiked ?? false;

        _posts[postIndex] = post.copyWith(
          isLiked: !isLiked,
          likesCount: isLiked ? post.likesCount - 1 : post.likesCount + 1,
        );
        notifyListeners();
      }

      // Make API call
      await _postService.toggleLike(userId: userId, postId: postId);
    } catch (e) {
      // Revert on error
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        final isLiked = post.isLiked ?? false;

        _posts[postIndex] = post.copyWith(
          isLiked: !isLiked,
          likesCount: isLiked ? post.likesCount + 1 : post.likesCount - 1,
        );
        notifyListeners();
      }
      _error = e.toString();
    }
  }

  // Report post
  Future<bool> reportPost({
    required String reporterId,
    required String reportedPostId,
    required String reason,
    String? description,
    String? groupId,
  }) async {
    try {
      await _postService.reportPost(
        reporterId: reporterId,
        reportedPostId: reportedPostId,
        reason: reason,
        description: description,
        groupId: groupId,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Get comments for a post
  Future<List<Comment>> getComments(String postId, {String? userId}) async {
    try {
      return await _postService.getComments(postId, userId: userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Create comment
  Future<Comment?> createComment({
    required String userId,
    required String postId,
    String? parentId,
    required String content,
  }) async {
    try {
      final comment = await _postService.createComment(
        userId: userId,
        postId: postId,
        parentId: parentId,
        content: content,
      );

      // Update post's comments count
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        _posts[postIndex] = post.copyWith(
          commentsCount: post.commentsCount + 1,
        );
        notifyListeners();
      }

      return comment;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Toggle comment like
  Future<void> toggleCommentLike(String commentId, String userId) async {
    try {
      await _postService.toggleLike(userId: userId, commentId: commentId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Thêm vào class PostProvider
  void setPostsForProfile(List<Post> myPosts) {
    _posts = myPosts;
    notifyListeners();
  }
}
