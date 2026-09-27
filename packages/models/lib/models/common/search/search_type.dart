// ignore_for_file: constant_identifier_names
import 'package:models/models/common/enum_with_label.dart';

// 以下路径常量取自 http/api.dart 的 Api 类（models 不能依赖 api 层）
const String _searchAll = '/x/web-interface/wbi/search/all/v2';
const String _searchByType = '/x/web-interface/wbi/search/type';

enum SearchType implements EnumWithLabel {
  all('综合', api: _searchAll),
  // 视频：video
  video('视频'),
  // 番剧：media_bangumi,
  media_bangumi('番剧'),
  // 影视：media_ft
  media_ft('影视'),
  // 直播间及主播：live
  // live,
  // 直播间：live_room
  live_room('直播间'),
  // 主播：live_user
  // live_user,
  // 话题：topic
  // topic,
  // 用户：bili_user
  bili_user('用户'),
  // 专栏：article
  article('专栏'),
  ;

  // 相簿：photo
  // photo

  @override
  final String label;
  final String api;
  const SearchType(this.label, {this.api = _searchByType});
}
