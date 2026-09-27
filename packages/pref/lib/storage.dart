import 'dart:convert';
import 'dart:typed_data';

import 'package:models/models/model_owner.dart';
import 'package:models/models/user/danmaku_rule_adapter.dart';
import 'package:models/models/user/info.dart';
import 'package:core/path_utils.dart';
import 'package:core/set_int_adapter.dart';
import 'package:pref/storage_pref.dart';
import 'package:core/utils.dart';
import 'package:hive_ce/hive.dart';
import 'package:path/path.dart' as path;

/// 账号存储的注入接口。
///
/// 账号实现（`Accounts` / `LoginAccount` / cookie adapter）依赖 http 与 pages，
/// 位于本包之上的 api 层。为避免 `pref → api` 的反向依赖，这里只声明接口，
/// 由宿主在 [GStorage.init] 之前通过 [GStorage.bindAccounts] 注入实现。
abstract interface class AccountsStorage {
  /// 打开并初始化账号盒。
  Future<void> init();

  /// 清空账号盒。
  Future<void> clear();

  /// 账号盒本体，用于 compact / close。
  Box<dynamic> get box;

  /// 注册账号相关的 Hive 适配器。
  void registerAdapters();
}

abstract final class GStorage {
  /// 账号存储实现，由宿主注入。
  static AccountsStorage? accounts;

  /// 注入账号存储实现，必须在 [init] 之前调用。
  static void bindAccounts(AccountsStorage accounts) =>
      GStorage.accounts = accounts;

  static late final Box<UserInfoData> userInfo;
  static late final Box<dynamic> historyWord;
  static late final Box<dynamic> localCache;
  static late final Box<dynamic> setting;
  static late final Box<dynamic> video;
  static late final Box<int> watchProgress;
  static late final Box<Uint8List>? reply;

  static Future<void> init() async {
    Hive.init(path.join(appSupportDirPath, 'hive'));
    regAdapter();

    await Future.wait([
      // 登录用户信息
      Hive.openBox<UserInfoData>(
        'userInfo',
        compactionStrategy: (int entries, int deletedEntries) {
          return deletedEntries > 2;
        },
      ).then((res) => userInfo = res),
      // 本地缓存
      Hive.openBox(
        'localCache',
        compactionStrategy: (int entries, int deletedEntries) {
          return deletedEntries > 4;
        },
      ).then((res) => localCache = res),
      // 设置
      Hive.openBox('setting').then((res) => setting = res),
      // 搜索历史
      Hive.openBox(
        'historyWord',
        compactionStrategy: (int entries, int deletedEntries) {
          return deletedEntries > 10;
        },
      ).then((res) => historyWord = res),
      // 视频设置
      Hive.openBox('video').then((res) => video = res),
      if (accounts case final AccountsStorage a) a.init(),
      Hive.openBox<int>(
        'watchProgress',
        keyComparator: _intStrDescKeyComparator,
        compactionStrategy: (entries, deletedEntries) {
          return deletedEntries > 4;
        },
      ).then((res) => watchProgress = res),
    ]);

    if (Pref.saveReply) {
      reply = await Hive.openBox<Uint8List>(
        'reply',
        keyComparator: _intStrDescKeyComparator,
        compactionStrategy: (entries, deletedEntries) {
          return deletedEntries > 10;
        },
      );
    } else {
      reply = null;
    }
  }

  static String exportAllSettings() {
    return Utils.jsonEncoder.convert({
      setting.name: setting.toMap(),
      video.name: video.toMap(),
    });
  }

  static Future<void> importAllSettings(String data) =>
      importAllJsonSettings(jsonDecode(data));

  static Future<List<void>> importAllJsonSettings(
    Map<String, dynamic> map,
  ) {
    return Future.wait([
      setting.clear().then((_) => setting.putAll(map[setting.name])),
      video.clear().then((_) => video.putAll(map[video.name])),
    ]);
  }

  static void regAdapter() {
    Hive
      ..registerAdapter(OwnerAdapter())
      ..registerAdapter(UserInfoDataAdapter())
      ..registerAdapter(LevelInfoAdapter())
      ..registerAdapter(SetIntAdapter())
      ..registerAdapter(RuleFilterAdapter());
    accounts?.registerAdapters();
  }

  static Future<List<void>> compact() {
    return Future.wait([
      userInfo.compact(),
      historyWord.compact(),
      localCache.compact(),
      setting.compact(),
      video.compact(),
      if (accounts case final AccountsStorage a) a.box.compact(),
      watchProgress.compact(),
      ?reply?.compact(),
    ]);
  }

  static Future<List<void>> close() {
    return Future.wait([
      userInfo.close(),
      historyWord.close(),
      localCache.close(),
      setting.close(),
      video.close(),
      if (accounts case final AccountsStorage a) a.box.close(),
      watchProgress.close(),
      ?reply?.close(),
    ]);
  }

  static Future<List<void>> clear() {
    return Future.wait([
      userInfo.clear(),
      historyWord.clear(),
      localCache.clear(),
      setting.clear(),
      video.clear(),
      if (accounts case final AccountsStorage a) a.clear(),
      watchProgress.clear(),
      ?reply?.clear(),
    ]);
  }

  static int _intStrDescKeyComparator(dynamic k1, dynamic k2) {
    if (k1 is int) {
      if (k2 is int) {
        return k2.compareTo(k1);
      } else {
        return -1;
      }
    } else if (k2 is String) {
      final lenCompare = k2.length.compareTo((k1 as String).length);
      if (lenCompare == 0) {
        return k2.compareTo(k1);
      } else {
        return lenCompare;
      }
    } else {
      return 1;
    }
  }
}
