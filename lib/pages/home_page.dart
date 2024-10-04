// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/components/my_drawer.dart';
import 'package:chat_app/components/my_usertile.dart';
import 'package:chat_app/pages/chat_page.dart';
import 'package:chat_app/services/chat/chat_services.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ChatServices _chatServices = ChatServices();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
      drawer: const MyDrawer(),
      body: _buildUserList(),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder(
      stream: _chatServices.getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading users."));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No users available."));
        }

        final List<Map<String, dynamic>> users =
            List<Map<String, dynamic>>.from(snapshot.data!);

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index];
            return _buildUserListItem(userData, context);
          },
        );
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> userData, BuildContext context) {
    String currentUserID = _authService.getCurrentUser()!.uid;

    if (userData["email"] != _authService.getCurrentUser()!.email) {
      return FutureBuilder<int>(
        future:
            _chatServices.getUnreadMessageCount(userData["uid"], currentUserID),
        builder: (context, snapshot) {
          int unreadCount = snapshot.data ?? 0;

          return MyUsertile(
            text: userData["email"],
            trailing: _buildUnreadBadge(unreadCount),
            onTap: () async {
              // Mark messages as read when opening the chat
              await _chatServices.markMessagesAsRead(
                userData["uid"], // sender ID (the other person in the chat)
                currentUserID, // receiver ID (current user)
              );

              // Refresh the unread count in the UI
              setState(() {}); // This will trigger the UI to update

              // Navigate to chat page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    receiverEmail: userData["email"],
                    receiversID: userData["uid"],
                  ),
                ),
              );
            },
          );
        },
      );
    } else {
      return const SizedBox(); // Skip rendering for the current user
    }
  }

  // Unread message badge widget
  Widget _buildUnreadBadge(int unreadCount) {
    if (unreadCount > 0) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(
          minWidth: 20,
          minHeight: 20,
        ),
        child: Center(
          child: Text(
            unreadCount > 99 ? '99+' : unreadCount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else {
      return const SizedBox(); // No badge if no unread messages
    }
  }
}
