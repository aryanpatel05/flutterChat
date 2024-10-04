import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderID;
  final String senderEmail;
  final String receiverID;
  final String message;
  final Timestamp timestamp;
  final bool read; // New field to track whether the message is read

  Message({
    required this.message,
    required this.receiverID,
    required this.senderEmail,
    required this.senderID,
    required this.timestamp,
    this.read = false, // Default to unread when message is created
  });

  Map<String, dynamic> toMap() {
    return {
      'senderID': senderID,
      'senderEmail': senderEmail,
      'receiverID': receiverID,
      'timestamp': timestamp,
      'message': message,
      'read': read, // Include the read field in the map
    };
  }

  // Create a factory constructor for converting Firestore data to Message
  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      senderID: data['senderID'],
      senderEmail: data['senderEmail'],
      receiverID: data['receiverID'],
      message: data['message'],
      timestamp: data['timestamp'],
      read: data['read'] ?? false, // Set read flag, default to false if missing
    );
  }
}
