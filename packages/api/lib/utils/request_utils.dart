import 'package:flutter/widgets.dart' show ValueChanged, VoidCallback;
import 'dart:convert' show jsonEncode;

import 'package:api/grpc/im.dart';
import 'package:api/http/dynamics.dart';
import 'package:api/http/user.dart';
import 'package:api/http/validate.dart';
import 'package:api/utils/accounts.dart';
import 'package:core/loading_state.dart';
import 'package:core/storage_key.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:grpc/bilibili/im/type.pbenum.dart';
import 'package:grpc/bilibili/main/community/reply/v1.pb.dart' show ReplyInfo;
import 'package:models/models/dynamics/result.dart';
import 'package:models/models/login/model.dart';
import 'package:pref/storage.dart';
import 'package:pref/storage_pref.dart';

abstract final class RequestUtils {
  /// 由 app 层注入：弹出极验验证码 webview 并返回验证结果。
  /// 原实现为 `GeetestWebviewDialog.geetest`（lib/pages/login/geetest/），
  /// api 不允许依赖 pages，故改为回调注入；未注入时 validate 只做提示。
  static Future<Map<String, dynamic>?> Function(
    String gt,
    String challenge,
  )? geetest;

  static Future<void> syncHistoryStatus() async {
    final account = Accounts.history;
    if (!account.isLogin) {
      return;
    }
    final res = await UserHttp.historyStatus(account: account);
    if (res case Success(:final response)) {
      GStorage.localCache.put(LocalCacheKey.historyPause, response);
    }
  }

  // 1：小视频（已弃用）
  // 2：相簿
  // 3：纯文字
  // 4：直播（此类型不常用，见分享其他内容消息）
  // 5：视频
  // 6：专栏
  // 7：番剧（id 为 season_id）
  // 8：音乐
  // 9：国产动画（id 为 AV 号）
  // 10：图片
  // 11：动态
  // 16：番剧（id 为 epid）
  // 17：番剧
  // https://github.com/SocialSisterYi/bilibili-API-collect/tree/master/docs/message/private_msg_content.md
  static Future<bool> pmShare({
    required int receiverId,
    required Map content,
    String? message,
  }) async {
    final ownerMid = Accounts.main.mid;
    final contentRes = await ImGrpc.sendMsg(
      senderUid: ownerMid,
      receiverId: receiverId,
      content: jsonEncode(content),
      msgType: content['source'] is String
          ? MsgType.EN_MSG_TYPE_COMMON_SHARE_CARD
          : MsgType.EN_MSG_TYPE_SHARE_V2,
    );

    if (contentRes.isSuccess) {
      if (message?.isNotEmpty == true) {
        final msgRes = await ImGrpc.sendMsg(
          senderUid: ownerMid,
          receiverId: receiverId,
          content: jsonEncode({"content": message}),
          msgType: MsgType.EN_MSG_TYPE_TEXT,
        );
        return msgRes.isSuccess;
      } else {
        return true;
      }
    } else {
      return false;
    }
  }

  static ReplyInfo replyCast(Map res) {
    Map? emote = res['content']['emote'];
    emote?.forEach((key, value) {
      value['size'] = value['meta']['size'];
    });
    return ReplyInfo.create()..mergeFromProto3Json(
      res
        ..['content'].remove('members')
        ..['id'] = res['rpid']
        ..['member']['name'] = res['member']['uname']
        ..['member']['face'] = res['member']['avatar']
        ..['member']['level'] = res['member']['level_info']['current_level']
        ..['member']['vipStatus'] = res['member']['vip']['vipStatus']
        ..['member']['vipType'] = res['member']['vip']['vipType']
        ..['member']['officialVerifyType'] =
            res['member']['official_verify']['type']
        ..['content']['emotes'] = emote,
      ignoreUnknownFields: true,
    );
  }

  // 动态点赞
  static Future<void> onLikeDynamic(
    DynamicItemModel item,
    bool uiStatus,
    VoidCallback onSuccess,
  ) async {
    // 原 `feedBack()`（lib/utils/feed_back.dart）；它依赖 Pref，无法下沉到 core，
    // 现已归入 package:pref/feed_back.dart，此处内联避免 api 依赖 UI 工具层。
    if (Pref.feedBackEnable) {
      HapticFeedback.lightImpact();
    }

    final like = item.modules.moduleStat?.like;
    final status = like?.status ?? false;

    if (status ^ uiStatus) {
      SmartDialog.showToast(status ? '点赞成功' : '取消赞');
      onSuccess();
      return;
    }

    final res = await DynamicsHttp.thumbDynamic(
      dynamicId: item.idStr!,
      up: status ? 2 : 1, // 1 已点赞 2 不喜欢 0 未操作
    );
    if (res.isSuccess) {
      SmartDialog.showToast(status ? '取消赞' : '点赞成功');
      like
        ?..count = (like.count ?? 0) + (status ? -1 : 1)
        ..status = !status;
      onSuccess();
    } else {
      res.toast();
    }
  }

  static Future<void> validate(
    String vVoucher,
    ValueChanged<String> onSuccess,
  ) async {
    final res = await ValidateHttp.gaiaVgateRegister(vVoucher);
    if (!res.isSuccess) {
      res.toast();
      return;
    }

    final resData = res.data;
    if (resData == null) {
      SmartDialog.showToast("null data");
      return;
    }

    CaptchaDataModel captchaData = CaptchaDataModel();

    final geetest = resData['geetest'];
    String? gt = geetest?['gt'];
    String? challenge = geetest?['challenge'];
    captchaData.token = resData['token'];

    bool isGeeArgumentValid() {
      return gt?.isNotEmpty == true &&
          challenge?.isNotEmpty == true &&
          captchaData.token?.isNotEmpty == true;
    }

    if (!isGeeArgumentValid()) {
      SmartDialog.showToast("参数为空");
      return;
    }

    Future<void> gaiaVgateValidate() async {
      final res = await ValidateHttp.gaiaVgateValidate(
        challenge: captchaData.geetest?.challenge,
        seccode: captchaData.seccode,
        token: captchaData.token,
        validate: captchaData.validate,
      );
      if (res case Success(:final response?)) {
        if (response['is_valid'] == 1) {
          final griskId = response['grisk_id'];
          if (griskId is String) {
            onSuccess(griskId);
          }
        } else {
          SmartDialog.showToast('invalid');
        }
      } else {
        res.toast();
      }
    }

    final geetestFn = RequestUtils.geetest;
    if (geetestFn == null) {
      SmartDialog.showToast('未注入验证码回调');
      return;
    }
    final json = await geetestFn(gt!, challenge!);
    if (json != null) {
      captchaData
        ..validate = json['geetest_validate']
        ..seccode = json['geetest_seccode']
        ..geetest = GeetestData(
          challenge: json['geetest_challenge'],
          gt: gt,
        );
      gaiaVgateValidate();
    }
  }
}
