import 'package:api/http/init.dart';
import 'package:api/http/search.dart';
import 'package:api/utils/accounts/account.dart';
import 'package:core/id_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:models/models_new/video/video_detail/dimension.dart';

abstract final class UrlUtils {
  /// 由 app 层注入：跳转视频页（原 `PageUtils.toVideoPage`）。
  static void Function({
    int? aid,
    String? bvid,
    required int cid,
    Dimension? dimension,
  })? toVideoPage;

  /// 由 app 层注入：打开 webview（原 `PageUtils.handleWebview`）。
  static void Function(String url)? handleWebview;

  // 302重定向路由截取
  static Future<String?> parseRedirectUrl(
    String url, [
    bool returnOri = false,
  ]) async {
    String? redirectUrl;
    try {
      final response = await Request.dio.head(
        url,
        options: Options(
          followRedirects: false,
          validateStatus: (status) {
            return 200 <= status! && status < 400;
          },
          extra: {'account': AnonymousAccount()},
        ),
      );
      redirectUrl = response.headers['location']?.firstOrNull;
      if (kDebugMode) debugPrint('redirectUrl: $redirectUrl');
      if (redirectUrl != null && !redirectUrl.startsWith('http')) {
        redirectUrl = Uri.parse(url).resolve(redirectUrl).toString();
      }
    } catch (_) {}
    if (returnOri && redirectUrl == null) redirectUrl = url;
    if (redirectUrl != null && redirectUrl.endsWith('/')) {
      redirectUrl = redirectUrl.substring(0, redirectUrl.length - 1);
    }
    return redirectUrl;
  }

  // 匹配url路由跳转
  static Future<void> matchUrlPush(
    String pathSegment,
    String redirectUrl,
  ) async {
    final matchRes = IdUtils.matchAvorBv(input: pathSegment);
    if (matchRes.isNotEmpty) {
      final aid = matchRes.av;
      final bvid = matchRes.bv;
      final res = await SearchHttp.ab2cWithDimension(aid: aid, bvid: bvid);
      final cid = res?.cid;
      if (cid != null) {
        toVideoPage?.call(
          aid: aid,
          bvid: bvid,
          cid: cid,
          dimension: res!.dimension,
          // title: res.title,
        );
      }
    } else {
      if (redirectUrl.isNotEmpty) {
        handleWebview?.call(redirectUrl);
      } else {
        SmartDialog.showToast('matchUrlPush: $pathSegment');
      }
    }
  }
}
