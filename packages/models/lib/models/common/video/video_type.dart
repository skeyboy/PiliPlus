// 以下路径常量取自 http/api.dart 的 Api 类（models 不能依赖 api 层）
const String _ugcUrl = '/x/player/wbi/playurl';
const String _pgcUrl = '/pgc/player/web/v2/playurl';
const String _pugvUrl = '/pugv/player/web/playurl';

enum VideoType {
  ugc(
    type: 3,
    api: _ugcUrl,
  ),
  pgc(
    type: 4,
    api: _pgcUrl,
  ),
  pugv(
    type: 10,
    replyType: 33,
    api: _pugvUrl,
  ),
  ;

  final int type;
  final String api;
  final int replyType;
  const VideoType({
    required this.api,
    required this.type,
    this.replyType = 1,
  });
}
