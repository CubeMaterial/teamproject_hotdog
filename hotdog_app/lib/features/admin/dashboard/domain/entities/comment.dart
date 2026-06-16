class AdminComment {
  const AdminComment({
    required this.id,
    required this.postTitle,
    required this.authorName,
    required this.content,
    required this.contentImageUrl,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String postTitle;
  final String authorName;
  final String content;
  final String contentImageUrl;
  final String status;
  final DateTime createdAt;
}
