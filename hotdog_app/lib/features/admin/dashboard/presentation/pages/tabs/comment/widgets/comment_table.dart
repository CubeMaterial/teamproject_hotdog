import 'package:flutter/material.dart';

import '../../../../../domain/entities/comment.dart';
import '../../../../widgets/dashboard_data_table.dart';
import 'comment_detail_dialog.dart';
import 'comment_status_badge.dart';

class CommentTable extends StatelessWidget {
  const CommentTable({
    super.key,
    required this.comments,
    required this.startIndex,
    required this.selectedCommentIds,
    required this.onCommentSelected,
  });

  final List<AdminComment> comments;
  final int startIndex;
  final Set<String> selectedCommentIds;
  final void Function(String commentId, bool selected) onCommentSelected;

  @override
  Widget build(BuildContext context) {
    return DashboardDataTable(
      columns: const ['번호', '게시글 제품', '내용', '상태', '작성자', '일자'],
      horizontalMargin: 16,
      selectedRowIndexes: {
        for (final (index, comment) in comments.indexed)
          if (selectedCommentIds.contains(comment.id)) index,
      },
      onRowSelected: (index, selected) {
        onCommentSelected(comments[index].id, selected);
      },
      rows: [
        for (final (index, comment) in comments.indexed)
          [
            SizedBox(
              width: 25,
              child: Text(
                '${startIndex + index + 1}',
                textAlign: TextAlign.center,
              ),
            ),
            TextButton(
              onPressed: () => _showCommentDetail(context, comment),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF333333),
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 14),
              ),
              child: Text(_truncate(comment.postTitle)),
            ),
            Text(_truncate(comment.content)),
            CommentStatusBadge(label: comment.status),
            Text(comment.authorName),
            Text(_formatDate(comment.createdAt)),
          ],
      ],
    );
  }

  void _showCommentDetail(BuildContext context, AdminComment comment) {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '닫기',
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return CommentDetailDialog(comment: comment);
      },
    );
  }

  String _truncate(String text) {
    const maxLength = 20;
    final trimmedText = text.trim();

    if (trimmedText.length <= maxLength) {
      return trimmedText;
    }

    return '${trimmedText.substring(0, maxLength)}...';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
