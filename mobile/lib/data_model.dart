class DataModel {
  Message? message;
  List<Message>? previousMessages;

  DataModel({this.message, this.previousMessages});

  DataModel.fromJson(Map<String, dynamic> json) {
    message =
    json['message'] != null ? new Message.fromJson(json['message']) : null;
    if (json['previous_messages'] != null) {
      previousMessages = <Message>[];
      json['previous_messages'].forEach((v) {
        previousMessages!.add(new Message.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.message != null) {
      data['message'] = this.message!.toJson();
    }
    if (this.previousMessages != null) {
      data['previous_messages'] =
          this.previousMessages!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Message {
  String? user;
  String? text;

  Message({this.user, this.text});

  Message.fromJson(Map<String, dynamic> json) {
    user = json['user'];
    text = json['text'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['user'] = this.user;
    data['text'] = this.text;
    return data;
  }
}
