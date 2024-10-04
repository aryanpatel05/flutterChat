import 'package:chat_app/services/chat/chat_services.dart';
import 'package:chat_app/services/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart'; // To detect keyboard visibility

class ChatPage extends StatefulWidget {
  final String receiverEmail;
  final String receiversID;

  ChatPage({super.key, required this.receiverEmail, required this.receiversID});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ChatServices _chatServices = ChatServices();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController =
      ScrollController(); // ScrollController

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addObserver(this); // To listen for keyboard visibility
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Listen for changes in app lifecycle and keyboard visibility
  @override
  void didChangeMetrics() {
    if (MediaQuery.of(context).viewInsets.bottom > 0) {
      // Keyboard is open, scroll to the bottom
      _scrollToBottom();
    }
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatServices.sendMessage(
          widget.receiversID, _messageController.text);
      _messageController.clear();
      _scrollToBottom(); // Scroll to bottom after sending a message
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverEmail),
      ),
      body: Column(
        children: [
          Expanded(child: buildMessageList(context)),
          _buildUserInput(context),
        ],
      ),
    );
  }

  Widget buildMessageList(BuildContext context) {
    String senderID = _authService.getCurrentUser()!.uid;
    return StreamBuilder<QuerySnapshot>(
        stream: _chatServices.getMessages(widget.receiversID, senderID),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text("Error loading messages.");
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Text("Loading...");
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Text("No messages yet.");
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom(); // Scroll to bottom when new data comes in
          });

          return ListView(
            controller:
                _scrollController, // Attach ScrollController to ListView
            children: snapshot.data!.docs
                .map((doc) => _buildMessageItem(doc, context))
                .toList(),
          );
        });
  }

  Widget _buildMessageItem(DocumentSnapshot doc, BuildContext context) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    bool isCurrentUser = data["senderID"] == _authService.getCurrentUser()!.uid;

    // Determine the bubble color based on sender and theme mode
    Color messageColor;
    if (isCurrentUser) {
      messageColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.green[600]! // Darker green in dark mode
          : Colors.blue[100]!; // Blue in light mode
    } else {
      messageColor = Theme.of(context).brightness == Brightness.dark
          ? Colors.grey[700]! // Darker grey in dark mode
          : Colors.grey[200]!; // Light grey in light mode
    }

    var alignment =
        isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;

    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: messageColor, // Set message background color
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              data["message"],
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInput(BuildContext context) {
    // Access the current theme's brightness (light or dark mode)
    bool isLightMode = Theme.of(context).brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Padding(
        // Added bottom padding for more space above the keyboard
        padding: const EdgeInsets.only(
          bottom: 50.0,
          left: 20,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "Type a message",
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                ),
              ),
            ),
            const SizedBox(width: 10), // Gap between text field and send button
            Container(
              decoration: const BoxDecoration(
                  color: Colors.green, shape: BoxShape.circle),
              margin: const EdgeInsets.only(right: 10),
              child: IconButton(
                onPressed: sendMessage,
                icon: Icon(
                  Icons.send,
                  color: isLightMode
                      ? Colors.white
                      : Colors.black, // Set icon color based on mode
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
