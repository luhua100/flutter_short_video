import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_short_video/video_model.dart';
import 'package:video_player/video_player.dart';

class HZVideoPlayerPro extends StatefulWidget {
  final String? tabbarValue;
  final VideoModel? model;
  int currentIndex = 0;
  final void Function()? playEndStatus;
  HZVideoPlayerPro(this.tabbarValue, this.model, this.playEndStatus,this.currentIndex);

  @override
  State<HZVideoPlayerPro> createState() => _HZVideoPlayerProState();
}

class _HZVideoPlayerProState extends State<HZVideoPlayerPro>
    with AutomaticKeepAliveClientMixin {
  late VideoPlayerController videoPlayerController;

  ///控制更新视频懒加载状态的更新
  Future? videoPlayerFuture;

  ///怎么去刷新数据 *** 也就是当前页面如果需要销毁的话

  @override
  void initState() {
    print(" 初始化 ====video ${widget.model?.url}");
    print("初始化  ====refresh ${widget.currentIndex}");

    videoPlayerController =
        VideoPlayerController.network(widget.model?.url ?? '');
    videoPlayerFuture = videoPlayerController.initialize().then((value) {
      videoPlayerController.play();
      setState(() {});
    }).onError((error, stackTrace) {});
    videoPlayerController.addListener(() {
      if (videoPlayerController.value.isInitialized &&
          videoPlayerController.value.isPlaying) {
        var currentPosition = videoPlayerController.value.position;
        var totalPosition = videoPlayerController.value.duration;
        String currentStr = currentPosition.toString().substring(2, 7);
        String totalStr = totalPosition.toString().substring(2, 7);
        int currentSec = videoPlayerController.value.position.inSeconds;
        int totalSec = videoPlayerController.value.duration.inSeconds;
        ///这里需要注意的是 你的视频总长时间和播放的进度的时间有可能不相等
        if (currentSec == totalSec || currentSec == totalSec - 1) {
          videoPlayerController.seekTo(Duration.zero);
          ///如果项目有业务需要  播放完成自动播放下一条 请打开注释
          // if (widget.playEndStatus != null) {
          //   widget.playEndStatus!();
          // }
        }
        setState(() {});
      }
    });
    super.initState();
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant HZVideoPlayerPro oldWidget) {
    super.didUpdateWidget(oldWidget);
  }


  @override
  void dispose() {
    videoPlayerController.removeListener(() {});
    videoPlayerController.dispose();
    videoPlayerFuture = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Stack(
      children: [
        ///播放区域
        createVideoPreview(),

        ///播放按钮
        createPlayButton(),

        ///线性进度条

        createLineProgress(),

        ///视频描述
        createPlayTextContent(),

        ///右侧信息介
        createUserInfo()
      ],
    );
  }

  createVideoPreview() {

    return FutureBuilder(
        future: videoPlayerFuture,
        builder: (BuildContext context, value) {
          if (value.connectionState == ConnectionState.done) {
            ///初始化完成
            // print("视频初始化的状态${value.connectionState}");
            return InkWell(
                onTap: () {
                  if (videoPlayerController.value.isInitialized) {
                    if (videoPlayerController.value.isPlaying) {
                      videoPlayerController.pause();
                    } else {
                      videoPlayerController.play();
                    }
                    setState(() {});
                  } else {
                    videoPlayerFuture =
                        videoPlayerController.initialize().then((value) {
                          videoPlayerController.play();
                          setState(() {});
                        });
                  }
                },
                child: videoPlayerController.value.aspectRatio != 16 / 9 ?  Center(
                  child: SizedBox.expand(
                 child: FittedBox(
                   fit: BoxFit.cover,
                   child: SizedBox(
                     height: 16,
                     width: 9,
                     child: VideoPlayer(videoPlayerController),
                   ),
                 )),
            ) : Center(child: AspectRatio(aspectRatio: videoPlayerController.value.aspectRatio,child:VideoPlayer(videoPlayerController))));


          } else {
            ///否则转圈
            return Container(
              alignment: Alignment.center,
              child: CircularProgressIndicator(),
            );
          }
        });
  }

  createPlayButton() {
    Widget itemWidget = Container();

    ///当前视频暂停时显示按钮
    if (videoPlayerController.value.isInitialized &&
        !videoPlayerController.value.isPlaying) {
      itemWidget = GestureDetector(
        onTap: () {
          if (videoPlayerController.value.isInitialized &&
              !videoPlayerController.value.isPlaying) {
            videoPlayerController.play();
          }
          setState(() {});
        },
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            //color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.all(Radius.circular(30))),
          child: Icon(
            Icons.play_circle,
            color: Colors.black38,
            size: 60,
          ),
        ),
      );
    }
    return Align(alignment: Alignment(0, 0), child: itemWidget);
  }

  createPlayTextContent() {
    return Positioned(
        bottom: 14,
        left: 0,
        right: 64,
        child: Container(
          height: 100,
          child: Text(
            '554545456456456456456456561554545456456456456456456561554545456456456456456456561554545456456456456456456561554545456456456456456456561554545456456456456456456561',
            style: TextStyle(color: Colors.white, fontSize: 13),
          ),
        ));
  }

  ///显示评论视图
  Widget showComment() {
    return Container(
      height: 300,
      child: Column(
        children: [
          SizedBox(height: 12),
          Stack(children: [
            Align(
                alignment: Alignment(0, 0),
                child: Text('评论区',
                    style: TextStyle(fontSize: 15, color: Colors.black87))),
            Align(
                alignment: Alignment(1, 0),
                child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.clear,
                          size: 20,
                          color: Colors.grey,
                        ))))
          ]),
          SizedBox(height: 12),
          Expanded(child: Container(
            child: ListView.builder(
                itemBuilder: (BuildContext context, int index) {
                  return Text("$index");
                }),
          ))
        ],
      ),
    );
  }

  ///显示分享视图
  Widget createShare() {
    return Container(
      height: 260,
      child: Column(
        children: [
          SizedBox(
            height: 12,
          ),
          Container(
              height: 190,
              child: GridView.count(
                //设置滚动方向
                scrollDirection: Axis.vertical,
                //设置列数
                crossAxisCount: 4,
                //设置内边距
                padding: EdgeInsets.all(10),
                //设置横向间距
                crossAxisSpacing: 10,
                //设置主轴间距
                mainAxisSpacing: 10,
                children: [
                  Container(
                      height: 80,
                      color: Colors.blue,
                      child: Text("*****------")),
                  Container(
                      height: 80,
                      color: Colors.red,
                      child: Text("*****------")),
                  Container(
                      height: 80,
                      color: Colors.yellow,
                      child: Text("*****------")),
                  Container(
                      height: 80,
                      color: Colors.pinkAccent,
                      child: Text("*****------")),
                  Container(
                      height: 80,
                      color: Colors.green,
                      child: Text("*****------")),
                  Container(
                      height: 80,
                      color: Colors.teal,
                      child: Text("*****------")),
                ],
              )),
          SizedBox(height: 12),
          GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                  color: Colors.red,
                  height: 44,
                  alignment: Alignment.center,
                  child: Text('取消',
                      style: TextStyle(color: Colors.black87, fontSize: 15))))
        ],
      ),
    );
  }

  createUserInfo() {

    return Positioned(
        right: 20,
        bottom: (MediaQuery.of(context).size.height / 2) - 135,
        child: Column(children: [
          GestureDetector(
              onTap: () {
                showModalBottomSheet(
                  //isDismissible: false,
                    context: context,
                    builder: (BuildContext context) {
                      return Container(
                        height: 270,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10))),
                        child: createShare(),
                      );
                    });
              },
              child: Container(
                child: Column(
                  children: [
                    Icon(
                      Icons.share,
                      size: 22,
                      color: Colors.white,
                    ),
                    Padding(
                        padding: EdgeInsets.only(top: 15),
                        child: Text("${widget.model?.shareNum ?? ""}",
                            style:
                            TextStyle(color: Colors.white, fontSize: 12))),
                  ],
                ),
              )),
          SizedBox(height: 20),
          GestureDetector(
              onTap: () {
                showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Container(
                          height: 230,
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  topRight: Radius.circular(10))),
                          child: showComment());
                    });
              },
              child: Container(
                child: Column(
                  children: [
                    Icon(
                      Icons.comment,
                      size: 22,
                      color: Colors.white,
                    ),
                    Padding(
                        padding: EdgeInsets.only(top: 15),
                        child: Text("${widget.model?.commentNum ?? ''}",
                            style:
                            TextStyle(color: Colors.white, fontSize: 12))),
                  ],
                ),
              )),
          SizedBox(
            height: 20,
          ),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Container(
                      height: 230,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10))),
                      child: Text('关注*************'),
                    );
                  });
            },
            child: Container(
              child: Column(
                children: [
                  Icon(
                    Icons.flare_outlined,
                    size: 22,
                    color: Colors.white,
                  ),
                  Padding(
                      padding: EdgeInsets.only(top: 15),
                      child: Text("${widget.model?.attensionNum ?? ""}",
                          style: TextStyle(color: Colors.white, fontSize: 12))),
                ],
              ),
            ),
          )
        ]));
  }

  createLineProgress() {
    if (videoPlayerController.value.isInitialized &&
        videoPlayerController.value.isPlaying) {
      int value = videoPlayerController.value.position.inSeconds;
      int total = videoPlayerController.value.duration.inSeconds;
      //print("currentValue $value");
      //print("totalValue $total");

      return Positioned(
          bottom: 30,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.transparent,
            height: 2,
            child: LinearProgressIndicator(
              value: value / total,
              color: Colors.white,
              minHeight: 2,
              backgroundColor: Colors.grey,
            ),
          ));
    } else {
      return Container();
    }
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => false;
}
