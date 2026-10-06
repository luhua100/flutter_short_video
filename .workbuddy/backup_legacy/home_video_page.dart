import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_short_video/short_video_widget.dart';
import 'package:flutter_short_video/video_model.dart';


class DouyinVideoPage extends StatefulWidget {
  const DouyinVideoPage({Key? key}) : super(key: key);

  @override
  State<DouyinVideoPage> createState() => _DouyinVideoPageState();
}

class _DouyinVideoPageState extends State<DouyinVideoPage>
    with SingleTickerProviderStateMixin  {
  List<String> tabTexts = ['关注', '推荐'];

  ///头部导航的widgets
  List<Widget> tabBars = [];

  ///推荐数组
  List<VideoModel> reVideoLists = [];

  ///关注数组
  List<VideoModel> careVideoLists = [];

  ///tabbar 控制器切换 推荐和关注
  TabController? tabController;

  /// page 控制上下滑动
  PageController? pageController;

  //  ///当前页数
  int currentIndex = 0;

  @override
  void initState() {

    ///初始化推荐数据
    initData();
    tabTexts.forEach((element) {
      tabBars.add(Text('$element'));
    });
    tabController =
        TabController(length: tabTexts.length, vsync: this, initialIndex: 1);
    pageController = PageController(initialPage: 0);
    super.initState();
  }




  void initData() {
    for (int i = 0; i < 3; i++) {
      VideoModel model = VideoModel();
      model.url = "https://api.amemv.com/aweme/v1/play/?video_id=v0200fbd0000bbp4qkelg9jt2h2a2qsg&line=0&ratio=720p&media_type=4&vr_type=0&test_cdn=None&improve_bitrate=0";
      model.attensionNum =  "推荐页关注$i";
      model.shareNum =  "推荐页分享$i";
      model.commentNum =  "推荐页评论$i";
      model.attension = false;
      reVideoLists.add(model);
    }
    for (int i = 0; i < 3; i++) {
      VideoModel model = VideoModel();
      model.url =  "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4";
      model.attensionNum = "关注页关注$i";
      model.shareNum = "关注页分享$i";
      model.commentNum = "关注页评论$i";
      model.attension = false;
      careVideoLists.add(model);
    }
  }

  Future<void> _onRefresh() async {


    print("tabController  index ${tabController?.index}");


    if (pageController?.page?.toInt() == 0) {
      await Future.delayed(Duration(seconds: 2));
      // reVideoLists.clear();
      // careVideoLists.clear();
      if (tabController?.index == 0){
        refreshRecomonData();
      }else{
        refreshCareData();
      }
      //setState(() {});
    } else {
      await Future.delayed(Duration.zero);
    }
  }

  Future<void> refreshRecomonData()  async{
    // https://aweme.snssdk.com/aweme/v1/play/?video_id=v0200f180000bcstfbv3cp53oaad7s00&line=0&ratio=720p&media_type=4&vr_type=0&test_cdn=None&improve_bitrate=0

    for (int i = 0; i < 3; i++) {
      VideoModel model = VideoModel();
      model.url =  "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4";
      model.attensionNum = "刷新推荐页关注$i";
      model.shareNum = "刷新推荐页分享$i";
      model.commentNum = "刷新推荐页评论$i";
      model.attension = false;
      reVideoLists.add(model);
    }
  }

  Future<void>  refreshCareData() async {
    for (int i = 0; i < 3; i++) {
      VideoModel model = VideoModel();
      model.url =  "https://aweme.snssdk.com/aweme/v1/play/?video_id=v0200f180000bcstfbv3cp53oaad7s00&line=0&ratio=720p&media_type=4&vr_type=0&test_cdn=None&improve_bitrate=0";
      model.attensionNum = "刷新关注页关注$i";
      model.shareNum = "刷新关注页分享$i";
      model.commentNum = "刷新关注页评论$i";
      model.attension = false;
      careVideoLists.add(model);
    }

  }



  Future<Null> _loadData(String value) async {
    await Future.delayed(Duration(seconds: 2));
    print("_loadData_loadData_loadData_loadData");

    ///模拟追加数据
    for (int i = 0; i < 1; i++) {
      VideoModel videoModel = VideoModel();
      videoModel.url =
      "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4";
      videoModel.attensionNum = value == "推荐" ? "推荐页关注$i" : "关注页关注$i";
      videoModel.shareNum = value == "推荐" ? "推荐页分享$i" : "关注页分享$i";
      videoModel.commentNum = value == "推荐" ? "推荐页评论$i" : "关注页评论$i";
      videoModel.attension = false;
      if (value == "推荐") {
      } else {}
      reVideoLists.add(videoModel);
      careVideoLists.add(videoModel);
      setState(() {});
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    tabController?.dispose();
    pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return bobyBuilder();
  }

  ///初始化页面数据
  Widget bobyBuilder() {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
              left: 0, top: 0, right: 0, bottom: 0, child: createGroundView()),
          Positioned(
              left: 0, top: 0, right: 0, bottom: 0, child: createTabbarView()),
          Positioned(
              left: 0, top: 54, right: 0, bottom: 0, child: createTabbar()),
        ],
      ),
    );
  }

  ///头部的导航栏
  Widget createTabbar() {
    return Container(
      alignment: Alignment.topCenter,
      child: TabBar(
        tabs: tabBars,
        controller: tabController,
        indicatorColor: Colors.white,
        indicatorSize: TabBarIndicatorSize.label,
        isScrollable: true,
        labelStyle: TextStyle(fontSize: 15, color: Colors.white),
        onTap: (value) {
          // reIsRefresh = false;
          // careIsRefresh = false;
          // setState(() {
          //
          // });
        },
      ),
    );
  }

  ///中间的显示栏
  Widget createTabbarView() {
    return TabBarView(
        controller: tabController,
        physics: NeverScrollableScrollPhysics(),
        children: tabTexts.map((e) => buildTableViewItemPage(e)).toList());
  }

  ///底部的黑色背景图
  Widget createGroundView() {
    return Container(
      decoration: BoxDecoration(color: Colors.black),
    );
  }

  ///创建pageView来展示上下滑动
  Widget buildTableViewItemPage(String e) {
    List<VideoModel> tempList = [];

    if (e == "推荐") {
      tempList = reVideoLists;
    } else {
      tempList = careVideoLists;
    }

    return RefreshIndicator(
        onRefresh: _onRefresh,
        child:PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: tempList.length,
            controller: pageController,
            onPageChanged: (index) {
              // reIsRefresh = false;
              // careIsRefresh = false;
              currentIndex = index;
              setState(() {});
              if (pageController?.position.userScrollDirection ==
                  ScrollDirection.reverse) {
                print("pageController index $index ${reVideoLists.length - 1}");
                if (index ==
                    (e == "推荐"
                        ? reVideoLists.length - 1
                        : careVideoLists.length - 1)) {
                  print("在这里你可以进行隐形的上拉加载操作");
                  _loadData(e);
                }
                print('向上滑动');
              } else {
                print('向下滑动');
              }
            },
            itemBuilder: (BuildContext context, int index) {
              VideoModel model = tempList[index];
              return buildTableViewItem(e, model);
            }));
  }

  buildTableViewItem(String value, VideoModel model) {
    //return Container(alignment: Alignment.center, child: Text('$value 页面 ${model.url}',style: TextStyle(color: Colors.white),),);
    return HZVideoPlayerPro(value, model, () {
      int num = pageController?.page?.toInt() ?? 0;
      num += 1;
      if (value == "推荐") {
        if (num != reVideoLists.length) {
          pageController?.animateToPage(num,
              duration: Duration(milliseconds: 500), curve: Curves.linear);
        }
      } else {
        if (num != careVideoLists.length) {
          pageController?.animateToPage(num,
              duration: Duration(milliseconds: 500), curve: Curves.linear);
        }
      }
    },currentIndex);
  }

// @override
// // TODO: implement wantKeepAlive
// bool get wantKeepAlive => false;
}
