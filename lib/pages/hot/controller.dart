import 'package:core/loading_state.dart';
import 'package:api/http/video.dart';
import 'package:models/models/model_hot_video_item.dart';
import 'package:core/controller/common_list_controller.dart';

class HotController
    extends CommonListController<List<HotVideoItemModel>, HotVideoItemModel> {
  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<LoadingState<List<HotVideoItemModel>>> customGetData() =>
      VideoHttp.hotVideoList(
        pn: page,
        ps: 20,
      );
}
