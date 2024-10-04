import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chat_app/models/message.dart';

class ChatServices {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String getCurrentUserID() {
    return _auth.currentUser?.uid ?? '';
  }

  // Send a message to Firestore
  Future<void> sendMessage(String receiverID, String message) async {
    final String currentUserID = getCurrentUserID();
    final String currentUserEmail = _auth.currentUser?.email ?? 'Unknown';
    final Timestamp timestamp = Timestamp.now();

    // Ensure consistent chat room ID by sorting the user IDs alphabetically
    List<String> ids = [currentUserID, receiverID];
    ids.sort(); // Guarantees both users use the same chatRoomID
    String chatRoomID = ids.join("_");

    Message newMessage = Message(
      message: message,
      receiverID: receiverID,
      senderEmail: currentUserEmail,
      senderID: currentUserID,
      timestamp: timestamp,
      read: false, // Mark the message as unread initially
    );

    // Add the new message to the 'messages' sub-collection of the chat room
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  // Get the messages stream for the chat between two users
  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    // Generate the same chatRoomID by sorting the IDs
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');

    // Fetch the messages from Firestore for this chat room
    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false) // Order by time (oldest first)
        .snapshots();
  }

  // Get users stream from Firestore
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection("Users").snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();
    });
  }

  // Get the count of unread messages for a specific chat
  Future<int> getUnreadMessageCount(String senderID, String receiverID) async {
    // Generate the same chatRoomID by sorting the IDs
    List<String> ids = [senderID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    // Fetch unread messages from Firestore
    QuerySnapshot unreadMessages = await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .where('receiverID', isEqualTo: receiverID)
        .where('read', isEqualTo: false) // Only fetch unread messages
        .get();

    // Return the count of unread messages
    return unreadMessages.docs.length;
  }

  // Mark all unread messages in the chat as read
  // Mark all unread messages in the chat as read and return the count
  Future<int> markMessagesAsRead(String senderID, String receiverID) async {
    List<String> ids = [senderID, receiverID];
    ids.sort();
    String chatRoomID = ids.join('_');

    // Fetch unread messages from Firestore
    QuerySnapshot unreadMessages = await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .where('receiverID', isEqualTo: receiverID)
        .where('read', isEqualTo: false)
        .get();

    // Mark each unread message as read
    for (var doc in unreadMessages.docs) {
      await doc.reference.update({'read': true});
    }

    // Return the count of unread messages after marking as read
    return unreadMessages.docs.length;
  }
}
