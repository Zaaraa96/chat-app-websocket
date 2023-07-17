class MessageModel {
  String? text;
  String? token;

  MessageModel({this.text, this.token});

  MessageModel.fromJson(Map<String, dynamic> json) {
    text = json['text'];
    token = json['token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['text'] = this.text;
    data['token'] = this.token;
    return data;
  }
}
