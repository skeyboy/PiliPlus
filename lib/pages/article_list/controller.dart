import 'package:api/http/dynamics.dart';
import 'package:core/loading_state.dart';
import 'package:models/models/model_owner.dart';
import 'package:models/models_new/article/article_list/article.dart';
import 'package:models/models_new/article/article_list/data.dart';
import 'package:models/models_new/article/article_list/list.dart';
import 'package:core/controller/common_list_controller.dart';
import 'package:get/get.dart';

class ArticleListController
    extends CommonListController<ArticleListData, ArticleListItemModel> {
  final id = Get.parameters['id']!;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  final list = Rxn<ArticleListInfo>();
  Owner? author;

  @override
  List<ArticleListItemModel>? getDataList(ArticleListData response) {
    list.value = response.list;
    author = response.author;
    return response.articles;
  }

  @override
  Future<LoadingState<ArticleListData>> customGetData() =>
      DynamicsHttp.articleList(id: id);
}
