import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

import '../../../../../domain/entities/comment.dart';

class CommentDetailDialog extends StatelessWidget {
  const CommentDetailDialog({super.key, required this.comment});

  static const _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  final AdminComment comment;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 13, color: Color(0xFF333333));

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: DefaultTextStyle(
          style: textStyle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '댓글 상세',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: const Color(0xFF333333),
                      iconSize: 30,
                      tooltip: '닫기',
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const Divider(height: 1, color: AppColors.border),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _DetailRow(
                          label: '작성자',
                          value: comment.authorName,
                          secondLabel: '작성일자',
                          secondValue: _formatDate(comment.createdAt),
                        ),
                        _DetailRow(
                          label: '게시글',
                          value: comment.postTitle,
                          expandedValue: true,
                        ),
                        _DetailRow(
                          label: '내용',
                          value: comment.content,
                          imageUrl: _imageUrl,
                          expandedValue: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? get _imageUrl {
    final path = comment.contentImageUrl.trim();

    if (path.isEmpty) {
      return null;
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    if (path.startsWith('/')) {
      return '$_apiBaseUrl$path';
    }

    return '$_apiBaseUrl/$path';
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _CommentImage extends StatelessWidget {
  const _CommentImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 13, color: Color(0xFF333333));

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.white.withValues(alpha: 0.6),
            child: const Text('이미지를 불러올 수 없습니다.', style: textStyle),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.secondLabel,
    this.secondValue,
    this.imageUrl,
    this.expandedValue = false,
  });

  final String label;
  final String value;
  final String? secondLabel;
  final String? secondValue;
  final String? imageUrl;
  final bool expandedValue;

  @override
  Widget build(BuildContext context) {
    final hasSecondPair = secondLabel != null && secondValue != null;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailLabelCell(label),
            Expanded(
              flex: expandedValue ? 3 : 1,
              child: _DetailValueCell(value, imageUrl: imageUrl),
            ),
            if (hasSecondPair) ...[
              _DetailLabelCell(secondLabel!),
              Expanded(child: _DetailValueCell(secondValue!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailLabelCell extends StatelessWidget {
  const _DetailLabelCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      color: AppColors.beige,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF333333),
        ),
      ),
    );
  }
}

class _DetailValueCell extends StatelessWidget {
  const _DetailValueCell(this.value, {this.imageUrl});

  final String value;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          constraints: const BoxConstraints(minHeight: 54),
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: hasImage ? 14 : 16,
          ),
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, color: Color(0xFF333333)),
          ),
        ),
        if (hasImage)
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: _CommentImage(url: imageUrl!),
          ),
      ],
    );
  }
}
