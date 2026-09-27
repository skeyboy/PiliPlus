import 'package:core/loading_state.dart';
import 'package:api/http/user.dart';
import 'package:models/models_new/follow/data.dart';
import 'package:PiliPlus/pages/follow_type/controller.dart';

class FollowedController extends FollowTypeController {
  @override
  Future<LoadingState<FollowData>> customGetData() =>
      UserHttp.followedUp(mid: mid, pn: page);
}
