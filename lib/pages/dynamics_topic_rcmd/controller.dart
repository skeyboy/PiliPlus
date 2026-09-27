import 'package:api/http/dynamics.dart';
import 'package:core/loading_state.dart';
import 'package:models/models_new/dynamic/dyn_topic_top/topic_item.dart';
import 'package:core/controller/common_list_controller.dart';

class DynTopicRcmdController
    extends CommonListController<List<TopicItem>?, TopicItem> {
  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  Future<LoadingState<List<TopicItem>?>> customGetData() =>
      DynamicsHttp.dynTopicRcmd();
}
