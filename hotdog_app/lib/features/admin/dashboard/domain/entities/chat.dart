class ChatStorage {
  const ChatStorage({
    required this.id,
    required this.chatContent,
    required this.chatTime,
    required this.staffSeq,
    required this.userSeq,
  });

  final String id;
  final String chatContent;
  final DateTime chatTime;
  final int staffSeq;
  final int userSeq;
}
