import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:yqplaymusic/common/utils/DataSaveManager.dart';
import 'package:yqplaymusic/common/utils/EventBusDistribute.dart';
import 'package:yqplaymusic/common/utils/SongInfoUtils.dart';

import '../../api/track.dart';
import 'ShareData.dart';

class Player {
  Player();
  // 当前播放音乐id
  String musicId = "1456673752";
  List<String> songIDs = [];
  // 私有播放器
  AudioPlayer? _audioPlayer;
  // 当前播放位置 微秒
  int position = 0;
  // 歌曲总时长
  int duration = 0;
  // 是否正在播放
  bool isPlaying = false;
  // cb 函数
  List<Function()> currentPositionCbs = [];
  // 事件总线监听
  StreamSubscription streamSubscription =
      EventBusManager.eventBus.on<ShareData>().listen((event) {
    // 获取音乐id
    if (event.mapData["musicID"] != null) {
      player.musicId = event.mapData["musicID"];
      // 持久化存储数据
      DataSaveManager.setLocalStorage("musicID", player.musicId);
    }

    // 播放暂停
    if (event.mapData["playAndPause"] != null) {
      if (event.mapData["playAndPause"]) {
        player.audioPlayer.play();
        player.isPlaying = true;
      } else {
        player.audioPlayer.pause();
        player.isPlaying = false;
      }
    }

    // 获取音乐播放集合
    if (event.mapData["songIDs"] != null) {
      player.songIDs = event.mapData["songIDs"];
    }

    // 下一首
    if (event.mapData["next"] != null) {
      if (player.songIDs.isNotEmpty) {
        int index = player.songIDs.indexOf(player.musicId);
        if (index + 1 == player.songIDs.length) {
          index = 0;
        } else {
          index++;
        }
        player.musicId = player.songIDs[index];
        player.getMusicUrl();
        player.audioPlayer.play();
        player.isPlaying = true;
        EventBusManager.eventBus.fire(ShareData(playAndPause: true));
      }
    }

    // 上一首
    if (event.mapData["previous"] != null) {
      if (player.songIDs.isNotEmpty) {
        int index = player.songIDs.indexOf(player.musicId);
        if (index - 1 == -1) {
          index = player.songIDs.length - 1;
        } else {
          index--;
        }
        player.musicId = player.songIDs[index];
        player.getMusicUrl();
        player.audioPlayer.play();
        player.isPlaying = true;
        EventBusManager.eventBus.fire(ShareData(playAndPause: true));
      }
    }

    // 新歌开始播放 放到最后面
    if (event.mapData["isPlaying"] != null) {
      if (event.mapData["isPlaying"]) {
        player.getMusicUrl();

        // 防止切换下一首时音乐残留
        if (player.position != 0) {
          // 创建异步任务
          Future.delayed(const Duration(seconds: 1), () {
            player.audioPlayer.play();
            player.isPlaying = true;
          });
        } else {
          player.audioPlayer.play();
          player.isPlaying = true;
        }
      } else {
        player.getMusicUrl();
      }
    }
  });

  AudioPlayer getAudioPlayer() {
    if (_audioPlayer == null) {
      _audioPlayer = AudioPlayer();
      // 监听播放进度
      _audioPlayer?.positionStream.listen((Duration position) {
        // print("onPositionChanged: ${position.inMilliseconds}");
        this.position = position.inMilliseconds;
        if (currentPositionCbs.isNotEmpty) {
          for (var function in currentPositionCbs) {
            function();
          }
        }

        _checkIsPlayNext();
      });

      // 获取歌曲总时长
      _audioPlayer?.durationStream.listen((Duration? duration) {
        this.duration = duration?.inMilliseconds ?? 0;
      });

      // 读取最后一次播放的歌曲
      DataSaveManager.getLocalStorage("musicID").then((value) {
        if(value != null) {
          musicId = value;
        }
        getMusicUrl();
      });
    }
    return _audioPlayer!;
  }

  // 检查是否可以播放下一首
  void _checkIsPlayNext() {
    if(position == duration && musicId.isNotEmpty && position != 0) {
      int index = player.songIDs.indexOf(player.musicId);
      if (index + 1 == player.songIDs.length) {
        index = 0;
      } else {
        index++;
      }
      player.musicId = player.songIDs[index];
      player.getMusicUrl();
      player.audioPlayer.play();
      player.isPlaying = true;
    }
  }


  // 设置cb函数
  void setCurrentPositionCb(Function() currentPositionCb) {
    currentPositionCbs.add(currentPositionCb);
  }

  // 移除cb函数
  void removeCurrentPositionCb(Function() currentPositionCb) {
    currentPositionCbs.remove(currentPositionCb);
  }

  // 获取音乐url和歌曲信息
  void getMusicUrl() {
    // 获取歌曲信息
    trackManager.getMusicDetail(ids: [player.musicId]).then((value) {
      var res = value.data is String ? jsonDecode(value.data) : value.data;

      String musicName = SongInfoUtils().getSongName(res);
      String musicArtist = SongInfoUtils().getArtists(res);
      String musicImageUrl =  "${SongInfoUtils().getImageUrl(res)}?param=224y224";
      EventBusManager.eventBus.fire(
        ShareData(
          musicID: player.musicId,
          musicName: musicName,
          musicArtist: musicArtist,
          musicImageUrl: musicImageUrl,
        ),
      );

      // 持久化存储数据
      DataSaveManager.setLocalStorage("musicID", player.musicId);
      DataSaveManager.setLocalStorage("musicName", musicName);
      DataSaveManager.setLocalStorage("musicArtist", musicArtist);
      DataSaveManager.setLocalStorage("musicImageUrl", musicImageUrl);
    });

    // 获取音乐url
    trackManager.getMusicUrl(id: player.musicId).then((value) async {
      var res = value.data is String ? jsonDecode(value.data) : value.data;
      // developer.log(res.toString());

      // 判断文件缓存是否存在
      Directory directory = await getTemporaryDirectory();
      String path =
          "${directory.path}/lockCachingAudioSource/${player.musicId}.${res["data"][0]["type"]}";
      File file = File(path);
      bool isExists = await file.exists();
      if (isExists) {
        // 如果存在缓存直接播放
        await player.audioPlayer.setFilePath(path);
      } else {
        // 处理url
        String url = res["data"][0]["url"];
        // 去除字符串 ?authSecret= 之后的内容 防止音乐识别问题
        RegExp regex = RegExp(r'\?authSecret=[^&]*');
        url = url.replaceAll(regex, "");

        LockCachingAudioSource lockCachingAudioSource = LockCachingAudioSource(
          Uri.parse(url),
          cacheFile: File(
              "${directory.path}/lockCachingAudioSource/${player.musicId}.${res["data"][0]["type"]}"),
        );
        await player.audioPlayer.setAudioSource(lockCachingAudioSource);
      }
    });
  }

  // 获取播放器
  AudioPlayer get audioPlayer => getAudioPlayer();
}

final Player player = Player();
