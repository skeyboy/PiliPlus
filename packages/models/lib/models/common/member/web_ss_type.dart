// 以下路径常量取自 http/api.dart 的 Api 类（models 不能依赖 api 层）
const String _seasonArchives = '/x/polymer/web-space/seasons_archives_list';
const String _seriesArchives = '/x/series/archives';

enum WebSsType {
  season(_seasonArchives),
  series(_seriesArchives),
  ;

  final String api;
  const WebSsType(this.api);
}
