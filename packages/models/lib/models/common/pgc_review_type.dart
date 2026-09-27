// 以下路径常量取自 http/api.dart 的 Api 类（models 不能依赖 api 层）
const String _pgcReviewL = '/pgc/review/long/list';
const String _pgcReviewS = '/pgc/review/short/list';

enum PgcReviewType {
  long(label: '长评', api: _pgcReviewL),
  short(label: '短评', api: _pgcReviewS),
  ;

  final String label;
  final String api;
  const PgcReviewType({
    required this.label,
    required this.api,
  });
}

enum PgcReviewSortType {
  def('默认', 0),
  latest('最新', 1),
  ;

  final int sort;
  final String label;
  const PgcReviewSortType(this.label, this.sort);
}
