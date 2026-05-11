class ChatMessage {
  String? messageId;
  String? senderId;
  String? senderName;
  String? message;
  String? timestamp;
  String? messageType; // "text", "image", etc.

  ChatMessage({
    this.messageId,
    this.senderId,
    this.senderName,
    this.message,
    this.timestamp,
    this.messageType = "text",
  });

  Map<String, dynamic> toJson() {
    return {
      "senderId": senderId,
      "senderName": senderName,
      "message": message,
      "timestamp": timestamp,
      "messageType": messageType,
    };
  }

  factory ChatMessage.fromJson(Map<dynamic, dynamic> json) {
    return ChatMessage(
      messageId: json["messageId"],
      senderId: json["senderId"],
      senderName: json["senderName"],
      message: json["message"],
      timestamp: json["timestamp"],
      messageType: json["messageType"],
    );
  }
}