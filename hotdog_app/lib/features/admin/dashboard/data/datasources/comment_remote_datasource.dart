import '../../../../../core/network/api_client.dart';
import '../../../../../core/network/api_routes.dart';
import '../../../../../core/network/model_mapper.dart';
import '../models/comment_model.dart';

class CommentRemoteDataSource {
  CommentRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  Future<List<AdminCommentModel>> getComments() async {
    final data = await _apiClient.getList(ApiRoutes.comments);

    return ModelMapper.mapList(
      data,
      AdminCommentModel.fromJson,
      label: 'comments',
    );
  }

  Future<void> deleteComment(String commentId) async {
    await _apiClient.deleteMap('${ApiRoutes.comments}$commentId');
  }
}
