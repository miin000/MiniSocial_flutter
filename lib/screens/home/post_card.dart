import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/post_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/post_provider.dart';
import 'comments_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PostCard extends StatefulWidget {
  final Post post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  @override
  void initState() {
    super.initState();
    // Configure timeago for Vietnamese
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
                  child: widget.post.userAvatar != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: widget.post.userAvatar!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Text(
                              widget.post.userName?.substring(0, 1).toUpperCase() ?? 'U',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      : Text(
                          widget.post.userName?.substring(0, 1).toUpperCase() ?? 'U',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.userName ?? 'Người dùng',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        widget.post.createdAt != null
                            ? timeago.format(widget.post.createdAt!, locale: 'vi')
                            : '',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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

          // Post media
          if (widget.post.mediaUrls != null && widget.post.mediaUrls!.isNotEmpty)
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: widget.post.mediaUrls!.length,
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
              // Like button
              TextButton.icon(
                onPressed: () {
                  postProvider.toggleLike(widget.post.id!, userId);
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
              
              // Comment button
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
              
              // Share button (coming soon)
              TextButton.icon(
                onPressed: () {
                  Fluttertoast.showToast(
                    msg: 'Tính năng đang phát triển - sẽ tích hợp vào chat',
                    backgroundColor: Colors.orange,
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
