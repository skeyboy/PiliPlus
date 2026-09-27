import 'package:core/loading_state.dart';
import 'package:api/http/user.dart';
import 'package:models/models_new/follow/data.dart';
import 'package:PiliPlus/pages/follow_type/controller.dart';

class FollowSameController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.sameFollowing(mid: mid, pn: page);
}
