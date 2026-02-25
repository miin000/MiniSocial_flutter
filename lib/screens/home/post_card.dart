import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import '../../providers/group_provider.dart';
import 'comments_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/app_config.dart';
import 'package:flutter/services.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('vi', timeago.ViMessages());
  }

  void _showReportDialog() {
    final reasons = [
      'Spam hoặc gây hiểu lầm',
      'Nội dung không phù hợp',
      'Bạo lực hoặc nguy hiểm',
      'Quấy rối hoặc bắt nạt',
      'Vi phạm quyền riêng tư',
      'Khác',
    ];

    String? selectedReason;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Báo cáo bài viết'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vui lòng chọn lý do báo cáo:'),
              const SizedBox(height: 16),
              ...reasons.map((reason) => RadioListTile<String>(
                title: Text(reason, style: const TextStyle(fontSize: 14)),
                value: reason,
                groupValue: selectedReason,
                onChanged: (value) {
                  setState(() {
                    selectedReason = value;
                  });
                },
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final postProvider = Provider.of<PostProvider>(context, listen: false);

                final success = await postProvider.reportPost(
                  reporterId: authProvider.user!.id!,
                  reportedPostId: widget.post.id!,
                  reason: selectedReason!,
                );

                if (mounted) {
                  Navigator.pop(context);
                  Fluttertoast.showToast(
                    msg: success ? 'Đã gửi báo cáo' : 'Lỗi khi gửi báo cáo',
                    backgroundColor: success ? Colors.green : Colors.red,
                  );
                }
              },
              child: const Text('Gửi'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostOptions() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwner = authProvider.user?.id == widget.post.userId;

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwner)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa bài viết'),
                onTap: () async {
                  Navigator.pop(context);
                  final postProvider = Provider.of<PostProvider>(context, listen: false);
                  final success = await postProvider.deletePost(widget.post.id!);
                  if (success && mounted) {
                    Fluttertoast.showToast(
                      msg: 'Đã xóa bài viết',
                      backgroundColor: Colors.green,
                    );
                  }
                },
              ),
            if (!isOwner)
              ListTile(
                leading: const Icon(Icons.flag, color: Colors.red),
                title: const Text('Báo cáo bài viết'),
                onTap: () {
                  Navigator.pop(context);
                  _showReportDialog();
                },
              ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Hủy'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final postProvider = Provider.of<PostProvider>(context);
    final userId = authProvider.user?.id ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFF3b82f6),
                  child: widget.post.userAvatar != null && widget.post.userAvatar!.isNotEmpty
                      ? ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: widget.post.userAvatar!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Text(
                        // An toàn: lấy ký tự đầu nếu có
                        (widget.post.userName?.isNotEmpty == true
                            ? widget.post.userName![0].toUpperCase()
                            : (widget.post.username?.isNotEmpty == true
                            ? widget.post.username![0].toUpperCase()
                            : 'U')),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                      : Text(
                    (widget.post.userName?.isNotEmpty == true
                        ? widget.post.userName![0].toUpperCase()
                        : (widget.post.username?.isNotEmpty == true
                        ? widget.post.username![0].toUpperCase()
                        : 'U')),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        // Ưu tiên: userName (fullName) → username → fallback
                        (widget.post.userName?.isNotEmpty == true
                            ? widget.post.userName!
                            : (widget.post.username?.isNotEmpty == true
                            ? '@${widget.post.username!}'
                            : 'Người dùng')),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (widget.post.userName != null &&
                          widget.post.userName!.isNotEmpty &&
                          widget.post.userName != widget.post.username)
                        Text(
                          widget.post.userName!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      Row(
                        children: [
                          Text(
                            widget.post.createdAt != null
                                ? timeago.format(widget.post.createdAt!, locale: 'vi')
                                : 'Vừa xong',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            widget.post.visibility == 'friends'
                                ? Icons.people
                                : widget.post.visibility == 'private'
                                    ? Icons.lock
                                    : Icons.public,
                            size: 13,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: _showPostOptions,
                ),
              ],
            ),
          ),

          // Post content
          if (widget.post.content != null && widget.post.content!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                widget.post.content!,
                style: const TextStyle(fontSize: 15),
              ),
            ),

          const SizedBox(height: 8),

          // Post media with carousel indicator
          if (widget.post.mediaUrls != null && widget.post.mediaUrls!.isNotEmpty)
            Stack(
              children: [
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    itemCount: widget.post.mediaUrls!.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return CachedNetworkImage(
                        imageUrl: widget.post.mediaUrls![index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.error),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.post.mediaUrls!.length > 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${widget.post.mediaUrls!.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                if (widget.post.mediaUrls!.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.post.mediaUrls!.length,
                            (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentImageIndex == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 8),

          // Likes and comments count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.post.likesCount} lượt thích',
                  style: const TextStyle(color: Colors.grey),
                ),
                Text(
                  '${widget.post.commentsCount} bình luận',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton.icon(
                onPressed: () {
                  if (widget.post.groupId != null) {
                    final gp = Provider.of<GroupProvider>(context, listen: false);
                    gp.toggleLikeOnGroupPost(widget.post.id!, userId);
                  } else {
                    postProvider.toggleLike(widget.post.id!, userId);
                  }
                },
                icon: Icon(
                  widget.post.isLiked == true ? Icons.favorite : Icons.favorite_border,
                  color: widget.post.isLiked == true ? Colors.red : Colors.grey,
                ),
                label: Text(
                  'Thích',
                  style: TextStyle(
                    color: widget.post.isLiked == true ? Colors.red : Colors.grey,
                  ),
                ),
              ),

              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CommentsScreen(post: widget.post),
                    ),
                  );
                },
                icon: const Icon(Icons.comment_outlined, color: Colors.grey),
                label: const Text('Bình luận', style: TextStyle(color: Colors.grey)),
              ),

              TextButton.icon(
                onPressed: () {
                  final url = widget.post.groupId != null
                      ? '${AppConfig.apiBaseUrl.replaceAll('/api/v1', '')}/groups/${widget.post.groupId}/posts/${widget.post.id}'
                      : '${AppConfig.apiBaseUrl.replaceAll('/api/v1', '')}/posts/${widget.post.id}';
                  Clipboard.setData(ClipboardData(text: url));
                  Fluttertoast.showToast(
                    msg: 'Đã sao chép liên kết bài viết',
                    backgroundColor: Colors.green,
                  );
                },
                icon: const Icon(Icons.share_outlined, color: Colors.grey),
                label: const Text('Chia sẻ', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}