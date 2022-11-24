class VideoModel{

  String? url;
  bool? attension;
  String? attensionNum;
  String? shareNum;
  String? commentNum;

  VideoModel({this.url, this.attension = false,this.attensionNum,this.shareNum,this.commentNum});

  factory VideoModel.fromJson(Map<String,dynamic> json) {
    return VideoModel(
        url:  json['url'],
        attension: json['attension'],
        attensionNum: json['attensionNum'],
        shareNum: json['shareNum'],
        commentNum: json['commentNum']);
  }


}