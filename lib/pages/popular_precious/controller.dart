import 'package:core/loading_state.dart';
import 'package:api/http/video.dart';
import 'package:models/models/model_hot_video_item.dart';
import 'package:models/models_new/popular/popular_precious/data.dart';
import 'package:core/controller/common_list_controller.dart';

class PopularPreciousController
    extends CommonListController<PopularPreciousData, HotVideoItemModel> {
  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  int? mediaId;

  @override
  List<HotVideoItemModel>? getDataList(PopularPreciousData response) {
    mediaId = response.mediaId;
    return response.list;
  }

  @override
  Future<LoadingState<PopularPreciousData>> customGetData() =>
      VideoHttp.popularPrecious(page: page);
}
