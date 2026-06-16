import 'package:flutter/material.dart';
import 'package:hotdog_app/core/theme/app_colors.dart';

import '../../../../domain/entities/comment.dart';
import '../../../view_models/comment_view_model.dart';
import '../../../widgets/dashboard_paginated_section.dart';
import '../../../widgets/dashboard_tab_header.dart';
import 'widgets/comment_filter_bar.dart';
import 'widgets/comment_table.dart';

class CommentManageTab extends StatefulWidget {
  const CommentManageTab({super.key, required this.viewModel});

  final CommentViewModel viewModel;

  @override
  State<CommentManageTab> createState() => _CommentManageTabState();
}

class _CommentManageTabState extends State<CommentManageTab> {
  final Set<String> _selectedCommentIds = {};
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final comments = widget.viewModel.comments;
    _removeDeletedSelections(comments);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const DashboardTabHeader(
          title: '댓글 관리',
          subtitle: '댓글 내용과 공개 상태를 관리합니다.',
        ),
        const SizedBox(height: 16),
        const CommentFilterBar(),
        const SizedBox(height: 16),
        DashboardPaginatedSection(
          items: comments,
          headerBuilder: (pageSizeSelector) => Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                pageSizeSelector,
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  height: 45,
                  child: FilledButton(
                    onPressed: _isDeleting ? null : _deleteSelectedComments,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.deepOrange,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.deepOrange,
                      disabledForegroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, size: 22),
                        SizedBox(width: 2),
                        Text(
                          '삭제',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          tableBuilder: (comments) => CommentTable(
            comments: comments,
            startIndex: 0,
            selectedCommentIds: _selectedCommentIds,
            onCommentSelected: _setCommentSelected,
          ),
          indexedTableBuilder: (comments, startIndex) => CommentTable(
            comments: comments,
            startIndex: startIndex,
            selectedCommentIds: _selectedCommentIds,
            onCommentSelected: _setCommentSelected,
          ),
        ),
      ],
    );
  }

  void _setCommentSelected(String commentId, bool selected) {
    setState(() {
      if (selected) {
        _selectedCommentIds.add(commentId);
      } else {
        _selectedCommentIds.remove(commentId);
      }
    });
  }

  Future<void> _deleteSelectedComments() async {
    if (_selectedCommentIds.isEmpty) {
      return;
    }

    final confirmed = await _showDeleteConfirmDialog();

    if (!confirmed) {
      return;
    }

    final ids = _selectedCommentIds.toSet();

    setState(() => _isDeleting = true);

    try {
      await widget.viewModel.deleteComments(ids);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedCommentIds.removeAll(ids);
        _isDeleting = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() => _isDeleting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('댓글 삭제에 실패했습니다: $error')));
    }
  }

  void _removeDeletedSelections(List<AdminComment> comments) {
    final commentIds = comments.map((comment) => comment.id).toSet();
    _selectedCommentIds.removeWhere((id) => !commentIds.contains(id));
  }

  Future<bool> _showDeleteConfirmDialog() async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '취소',
      transitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) {
        return const _DeleteConfirmDialog();
      },
    );

    return confirmed ?? false;
  }
}

class _DeleteConfirmDialog extends StatelessWidget {
  const _DeleteConfirmDialog();

  static const _red = Color(0xFFF50000);
  static const _buttonGray = Color(0xFFE0E0E0);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              color: _red,
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const Text(
                '삭제 하시겠습니까?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 12),
              child: Text(
                '삭제한 내용은\n되돌릴 수 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 10, 40, 24),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: TextButton.styleFrom(
                          backgroundColor: _buttonGray,
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: const Text('취소', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: SizedBox(
                      height: 40,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(),
                        ),
                        child: const Text('확인', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
