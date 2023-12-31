import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:yqplaymusic/common/utils/SongInfoUtils.dart';
import 'package:yqplaymusic/components/TrackListItem.dart';

import '../common/utils/EventBusDistribute.dart';
import '../common/utils/ShareData.dart';
import '../common/utils/screenadaptor.dart';
import 'dart:developer' as developer;

class TrackList extends StatelessWidget {
  const TrackList(
      {super.key,
      required this.type,
      required this.tracks,
      this.columnCount = 4,
      this.isShowSongAlbumNameAndTimes = false});

  // 类型
  final String type;
  // 歌单列表
  final List tracks;
  // 显示几列
  final int columnCount;
  // 是否显示歌曲的专辑和歌曲时间信息
  final bool isShowSongAlbumNameAndTimes;

  String _getMusicID(String type, Map item) {
    switch (type) {
      case "playlist":
        return item["id"].toString();
      case "sliverCloudDisk":
        return item["song"]["id"].toString();
    }
    return "0";
  }

  Map _getTrack(String type, Map item) {
    switch (type) {
      case "playlist":
        return item;
      case "sliverCloudDisk":
        return item["simpleSong"];
    }
    return {};
  }

  Widget _bulidTrackList() {
    return GridView.builder(
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          crossAxisSpacing: 5,
          mainAxisSpacing: 5,
          childAspectRatio: screenAdaptor.getLengthByOrientation(3.33, 3.14)),
      itemCount: 12,
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            // 发送事件
            EventBusManager.eventBus.fire(ShareData(
              musicID: tracks[index]["id"].toString(),
              isPlaying: true,
              playAndPause: true,
              songIDs: SongInfoUtils().getMapSongIDs(tracks),
            ));
          },
          borderRadius: BorderRadius.circular(
              screenAdaptor.getLengthByOrientation(10.w, 8.w)),
          child: TrackListItem(
            track: tracks[index],
            subTitleAndArtistPaddingLeft: [65.w, 45.w],
            subTitleAndArtistPaddingRight: [18.w, 3.w],
            artistPaddingTop: [30.w, 18.w],
            subTitleFontSize: [14.sp, 8.4.sp],
            artistFontSize: [12.sp, 7.3.sp],
          ),
        );
      },
    );
  }

  Widget _buildSliverSongsList(String type) {
    // developer.log(tracks[0].toString());
    return SliverAlignedGrid.count(
      crossAxisCount: columnCount,
      mainAxisSpacing: 5,
      itemCount: tracks.length,
      itemBuilder: (BuildContext context, int index) {
        return InkWell(
          onTap: () {
            // 发送事件
            EventBusManager.eventBus.fire(ShareData(
              musicID: _getMusicID(type, tracks[index]),
              isPlaying: true,
              playAndPause: true,
              songIDs: SongInfoUtils().getMapSongIDs(tracks),
            ));
          },
          borderRadius: BorderRadius.circular(
              screenAdaptor.getLengthByOrientation(10.w, 8.w)),
          child: SizedBox(
            height: screenAdaptor.getLengthByOrientation(70.h, 120.h),
            child: TrackListItem(
              track: _getTrack(type, tracks[index]),
              subTitleAndArtistPaddingLeft: [81.w, 55.w],
              subTitleAndArtistPaddingRight: [400.w, 350.w],
              artistPaddingTop: [30.w, 20.w],
              subTitleFontSize: [16.sp, 10.sp],
              artistFontSize: [12.sp, 7.3.sp],
              isShowSongAlbumNameAndTimes: isShowSongAlbumNameAndTimes,
              albumNamePaddingLeft: [300.w, 300.w],
              albumNamePaddingRight: [80.w, 60.w],
              albumNamePaddingTop: [24.w, 17.w],
              albumNameFontSize: [16.sp, 10.sp],
              timePaddingTop: [24.w, 17.w],
              timeFontSize: [16.sp, 10.sp],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSliverTrackList() {
    // developer.log(tracks[0].toString());
    return SliverAlignedGrid.count(
      crossAxisCount: columnCount,
      mainAxisSpacing: 5,
      itemCount: tracks.length,
      itemBuilder: (BuildContext context, int index) {
        return InkWell(
          onTap: () {
            // 发送事件
            EventBusManager.eventBus.fire(ShareData(
              musicID: tracks[index]["song"]["id"].toString(),
              isPlaying: true,
              playAndPause: true,
              songIDs: SongInfoUtils().getMapSongIDs(tracks),
            ));
          },
          borderRadius: BorderRadius.circular(
              screenAdaptor.getLengthByOrientation(10.w, 8.w)),
          child: SizedBox(
            height: screenAdaptor.getLengthByOrientation(70.h, 120.h),
            child: TrackListItem(
              track: tracks[index]["song"],
              subTitleAndArtistPaddingLeft: [81.w, 55.w],
              subTitleAndArtistPaddingRight: [80.w, 50.w],
              artistPaddingTop: [30.w, 20.w],
              subTitleFontSize: [16.sp, 10.sp],
              artistFontSize: [12.sp, 7.3.sp],
              isShowCount: true,
              playCount: tracks[index]["playCount"].toString(),
              countPaddingTop: [22.w, 15.w],
              countFontSize: [20.sp, 14.sp],
            ),
          ),
        );
      },
    );
  }

  Widget switchType() {
    switch (type) {
      case "tracklist":
        return _bulidTrackList();
      case "sliverCloudDisk":
        return _buildSliverSongsList(type);
      case "sliverTrackList":
        return _buildSliverTrackList();
      case "playlist":
        return _buildSliverSongsList(type);
      default:
        return _bulidTrackList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return switchType();
  }
}
