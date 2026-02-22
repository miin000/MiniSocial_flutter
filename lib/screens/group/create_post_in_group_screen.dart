import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../models/group_model.dart';
import '../../models/group_post_model.dart';
import '../../providers/post_provider.dart';
import '../../providers/group_provider.dart';

class CreatePostInGroupScreen extends StatefulWidget {
  final GroupModel group;
  final String currentUserId;

  const CreatePostInGroupScreen({
    Key? key,
    required this.group,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<CreatePostInGroupScreen> createState() =>
      _CreatePostInGroupScreenState();
}

class _CreatePostInGroupScreenState
    extends State<CreatePostInGroupScreen> {
  final TextEditingController _contentController =
  TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _submitPost() {
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      Fluttertoast.showToast(
        msg: "Vui lòng nhập nội dung",
        backgroundColor: Colors.red,
      );
      return;
    }

    final postProvider =
        Provider.of<PostProvider>(context, listen: false);
    final groupProvider =
        Provider.of<GroupProvider>(context, listen: false);

    // Gọi API để tạo post trong group
    postProvider
        .createPost(
      userId: widget.currentUserId,
      content: content,
      groupId: widget.group.id,
    )
        .then((success) async {
      if (success) {
        // Refresh detail để lấy bài viết mới từ server
        await groupProvider.fetchGroupDetail(widget.group.id);
        Fluttertoast.showToast(
          msg: 'Đăng bài thành công!',
          backgroundColor: Colors.green,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        Fluttertoast.showToast(
          msg: 'Không thể đăng bài. Vui lòng thử lại.',
          backgroundColor: Colors.red,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Đăng trong: ${widget.group.name}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Nội dung",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitPost,
              child: const Text("Đăng"),
            ),
          ],
        ),
      ),
    );
  }
}