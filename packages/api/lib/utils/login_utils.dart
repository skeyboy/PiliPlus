import 'dart:async' show FutureOr;
import 'dart:io' show Platform;

import 'package:api/http/user.dart';
import 'package:api/utils/accounts.dart';
import 'package:api/utils/accounts/account.dart';
import 'package:api/utils/request_utils.dart';
import 'package:collection/collection.dart';
import 'package:core/loading_state.dart';
import 'package:core/utils.dart';
import 'package:crypto/crypto.dart' show Digest;
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as web;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:pref/storage.dart';
import 'package:pref/storage_pref.dart';

abstract final class LoginUtils {
  /// 由 app 层注入：Windows 的 WebViewEnvironment（原 `lib/main.dart` 全局变量）。
  static web.WebViewEnvironment? webViewEnvironment;

  /// 由 app / services 层注入：登录状态变更通知
  /// （原 `Get.find<AccountService>()` 写 face / isLogin）。
  static void Function({required String face, required bool isLogin})?
      onAccountChanged;

  /// 由 app 层注入：Linux 下清除 webview cookie
  /// （原 `LinuxCookieManager.deleteAllCookies()`，它依赖 plugin）。
  static FutureOr<void> Function()? deleteAllCookies;

  static FutureOr setWebCookie([Account? account]) {
    if (Platform.isLinux) return null;
    final cookies = (account ?? Accounts.main).cookieJar.toList();
    final webManager = web.CookieManager.instance(
      webViewEnvironment: webViewEnvironment,
    );
    return Future.wait(
      cookies.map(
        (cookie) => webManager.setCookie(
          url: web.WebUri(
            '${Platform.isWindows ? 'https://' : ''}${cookie.domain}',
          ),
          name: cookie.name,
          value: cookie.value,
          path: cookie.path ?? '/',
          domain: cookie.domain,
          isSecure: cookie.secure,
          isHttpOnly: cookie.httpOnly,
        ),
      ),
    );
  }

  static Future<void> onLoginMain() async {
    final account = Accounts.main;
    final res = await UserHttp.userInfo();
    if (res case Success(:final response)) {
      setWebCookie(account);
      RequestUtils.syncHistoryStatus();
      if (response.isLogin == true) {
        onAccountChanged?.call(face: response.face!, isLogin: true);

        SmartDialog.showToast('main登录成功');
        if (response != Pref.userInfoCache) {
          await GStorage.userInfo.put('userInfoCache', response);
        }
      }
    } else {
      // 获取用户信息失败
      final errMsg = res.toString();
      if (errMsg == '账号未登录') {
        await Accounts.deleteAll({account});
        SmartDialog.showNotify(
          msg: '登录失败，请检查cookie是否正确，$errMsg',
          notifyType: .warning,
        );
      } else {
        SmartDialog.showToast(errMsg);
      }
    }
  }

  static Future<void> onLogoutMain() {
    onAccountChanged?.call(face: '', isLogin: false);

    return Future.wait([
      if (Platform.isLinux)
        Future<void>.value(deleteAllCookies?.call())
      else
        web.CookieManager.instance(
          webViewEnvironment: webViewEnvironment,
        ).deleteAllCookies(),
      GStorage.userInfo.delete('userInfoCache'),
    ]);
  }

  static String generateBuvid() {
    final md5Str = Digest(
      List.generate(16, (_) => Utils.random.nextInt(256)),
    ).toString();
    return 'XY${md5Str[2]}${md5Str[12]}${md5Str[22]}$md5Str';
  }

  static final buvid = Pref.buvid;

  // static String getUUID() {
  //   return const Uuid().v4().replaceAll('-', '');
  // }

  // static String generateBuvid() {
  //   String uuid = getUUID() + getUUID();
  //   return 'XY${uuid.substring(0, 35).toUpperCase()}';
  // }

  static String genDeviceId() {
    // https://github.com/bilive/bilive_client/blob/2873de0532c54832f5464a4c57325ad9af8b8698/bilive/lib/app_client.ts#L62
    final time = DateTime.now();

    final List<int> bytes = [
      ...Iterable.generate(16, (_) => Utils.random.nextInt(256)),
      _dec2bcd(time.year ~/ 100),
      _dec2bcd(time.year % 100),
      _dec2bcd(time.month),
      _dec2bcd(time.day),
      _dec2bcd(time.hour),
      _dec2bcd(time.minute),
      _dec2bcd(time.second),
      ...Iterable.generate(8, (_) => Utils.random.nextInt(256)),
    ];
    final check = (bytes.sum & 0xFF).toRadixString(16).padLeft(2, '0');

    return Digest(bytes).toString() + check;
  }

  static int _dec2bcd(int dec) {
    assert(0 <= dec && dec < 100);
    return ((dec ~/ 10) << 4) | (dec % 10);
  }
}
