import 'package:core/loading_state.dart';
import 'package:api/http/member.dart';
import 'package:models/models_new/space/space_season_series/item.dart';
import 'package:models/models_new/space/space_season_series/season.dart';
import 'package:core/controller/common_list_controller.dart';

class SeasonSeriesController
    extends CommonListController<SpaceSsData, SpaceSsModel> {
  SeasonSeriesController(this.mid);
  final int mid;
  int? count;

  @override
  void onInit() {
    super.onInit();
    queryData();
  }

  @override
  List<SpaceSsModel>? getDataList(SpaceSsData response) {
    count = response.page?.total;
    return (response.seasonsList ?? <SpaceSsModel>[]) +
        (response.seriesList ?? <SpaceSsModel>[]);
  }

  @override
  void checkIsEnd(int length) {
    if (count != null && length >= count!) {
      isEnd = true;
    }
  }

  @override
  Future<LoadingState<SpaceSsData>> customGetData() =>
      MemberHttp.seasonSeriesList(
        mid: mid,
        pn: page,
      );
}
