/// B 站 grpc 协议栈。
///
/// 本包只含 protobuf 生成代码（`bilibili/**`）与 grpc 路径常量 `GrpcUrl`。
/// 生成代码有 100 个文件且互相按路径引用，全量 export 会引发命名冲突，
/// 因此约定**按路径导入**：
///
/// ```dart
/// import 'package:grpc/grpc.dart';              // GrpcUrl（等价 'package:grpc/url.dart'）
/// import 'package:grpc/bilibili/rpc.pb.dart';   // 具体 pb 类型
/// ```
///
/// 代码放在 `lib/` 而非 `lib/src/`，正是为了让跨包按路径导入不触发
/// `implementation_imports`。
library;

export 'url.dart';
