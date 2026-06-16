import '../../../../../core/network/json_readers.dart';
import '../../domain/entities/comment.dart';

class AdminCommentModel extends AdminComment {
  const AdminCommentModel({
    required super.id,
    required super.postTitle,
    required super.authorName,
    required super.content,
    required super.contentImageUrl,
    required super.status,
    required super.createdAt,
  });

  factory AdminCommentModel.fromJson(Map<String, dynamic> json) {
    return AdminCommentModel(
      id: JsonReaders.stringValue(json, ['id', 'review_seq']),
      postTitle: JsonReaders.stringValue(json, [
        'postTitle',
        'product_name',
      ], fallback: '게시글 없음'),
      authorName: JsonReaders.stringValue(json, [
        'authorName',
        'user_name',
      ], fallback: '회원'),
      content: JsonReaders.stringValue(json, ['content', 'review_content']),
      contentImageUrl: JsonReaders.stringValue(json, [
        'contentImageUrl',
        'review_image',
      ]),
      status: JsonReaders.stringValue(json, ['status'], fallback: '공개'),
      createdAt: JsonReaders.dateTimeValue(json, ['createdAt', 'review_date']),
    );
  }
}
