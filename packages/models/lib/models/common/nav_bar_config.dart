import 'package:models/models/common/enum_with_label.dart';

enum NavigationBarType implements EnumWithLabel {
  home('首页'),
  dynamics('动态'),
  mine('我的'),
  ;

  @override
  final String label;
  const NavigationBarType(this.label);
}
