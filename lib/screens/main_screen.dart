// lib/screens/main_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'home/home_screen.dart';
import 'friends/friends_screen.dart';
import 'chat/chat_screen.dart';
import 'group/group_screen.dart';
import 'notifications/notification_screen.dart';
import 'profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = <Widget>[
    HomeScreen(),
    FriendsScreen(),
    ChatScreen(),
    GroupScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initNotifications();
    });
  }

  Future<void> _initNotifications() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
    if (authProvider.user != null) {
      // Đợi Firebase Auth sign in xong trước khi start Firestore listener
      // signInFirebase() đã được gọi trong AuthProvider.login() / checkAuthStatus()
      // Chờ thêm 1 chút để đảm bảo Firebase Auth hoàn tất
      await Future.delayed(const Duration(milliseconds: 500));
      notifProvider.startListening(authProvider.user!.id);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Refresh unread count when switching to notification tab
    if (index == 4) {
      Provider.of<NotificationProvider>(context, listen: false)
          .fetchUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Consumer<NotificationProvider>(
        builder: (context, notifProvider, _) {
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: <BottomNavigationBarItem>[
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Trang chủ',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Bạn bè',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: 'Chat',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: 'Group',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: notifProvider.unreadCount > 0,
                  label: Text(
                    notifProvider.unreadCount > 99
                        ? '99+'
                        : notifProvider.unreadCount.toString(),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  child: const Icon(Icons.notifications),
                ),
                label: 'Thông báo',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor: const Color(0xFF3b82f6),
            unselectedItemColor: Colors.grey,
            onTap: _onItemTapped,
          );
        },
      ),
    );
  }
}