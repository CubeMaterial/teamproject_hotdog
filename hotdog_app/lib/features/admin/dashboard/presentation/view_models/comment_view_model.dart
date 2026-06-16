import 'package:flutter/foundation.dart';

import '../../domain/entities/comment.dart';
import '../../domain/usecases/delete_comments_usecase.dart';
import '../../domain/usecases/get_comments_usecase.dart';

class CommentViewModel extends ChangeNotifier {
  CommentViewModel(this._getCommentsUseCase, this._deleteCommentsUseCase);

  final GetCommentsUseCase _getCommentsUseCase;
  final DeleteCommentsUseCase _deleteCommentsUseCase;

  List<AdminComment> comments = [];

  Future<void> load() async {
    comments = await _getCommentsUseCase();
    notifyListeners();
  }

  Future<void> deleteComments(Iterable<String> commentIds) async {
    final ids = commentIds.toSet();

    if (ids.isEmpty) {
      return;
    }

    await _deleteCommentsUseCase(ids);
    comments = comments.where((comment) => !ids.contains(comment.id)).toList();
    notifyListeners();
  }
}
