// lib/screens/group/group_screen.dart

import 'package:flutter/material.dart';

class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Group'),
        backgroundColor: const Color(0xFF3b82f6),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Group Screen - Coming Soon'),
      ),
    );
  }
}