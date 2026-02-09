// lib/screens/group/create_post_in_group_screen.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreatePostInGroupScreen extends StatefulWidget {
  final String groupName;
  const CreatePostInGroupScreen({super.key, required this.groupName});

  @override
  State<CreatePostInGroupScreen> createState() => _CreatePostInGroupScreenState();
}

class _CreatePostInGroupScreenState extends State<CreatePostInGroupScreen> {
  final _contentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Đăng trong: ${widget.groupName}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _contentController, maxLines: 5, decoration: const InputDecoration(labelText: 'Nội dung')),
            // Add image
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Call API post in group
                Fluttertoast.showToast(msg: 'Đăng thành công!', backgroundColor: Colors.green);
                Navigator.pop(context);
              },
              child: const Text('Đăng'),
            ),
          ],
        ),
      ),
    );
  }
}