import 'package:core/http_constants.dart';

// 以下路径常量取自 http/api.dart 的 Api 类（models 不能依赖 api 层）
const String _spaceArchive =
    '${HttpString.appBaseUrl}/x/v2/space/archive/cursor';
const String _spaceChargingArchive =
    '${HttpString.appBaseUrl}/x/v2/space/archive/charging';
const String _spaceSeason = '${HttpString.appBaseUrl}/x/v2/space/season/videos';
const String _spaceSeries = '${HttpString.appBaseUrl}/x/v2/space/series';
const String _spaceBangumi = '${HttpString.appBaseUrl}/x/v2/space/bangumi';
const String _spaceComic = '${HttpString.appBaseUrl}/x/v2/space/comic';

enum ContributeType {
  video(_spaceArchive),
  charging(_spaceChargingArchive),
  season(_spaceSeason),
  series(_spaceSeries),
  bangumi(_spaceBangumi),
  comic(_spaceComic),
  ;

  final String api;
  const ContributeType(this.api);
}
