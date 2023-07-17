import 'dart:async';
import 'dart:convert';

import 'package:chat/token_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'data_model.dart';
import 'message_model.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter App Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final _channel = WebSocketChannel.connect(Uri.parse('ws://192.168.54.151:3000'));

  final ScrollController scrollController = ScrollController();

  bool isConnected= false;
  String token='';
  final FocusNode _focusNode = FocusNode();
  late final List<Message> messages;
  @override
  void initState() {
    messages = [];
    _channel.stream.listen((event) {
      DataModel data= DataModel.fromJson(json.decode(event));
      print(data.toJson());
      if(data.previousMessages?.isNotEmpty?? false)
        {
          messages.addAll(data.previousMessages??[]);
          // for (PreviousMessage item in data.previousMessages??[])
          // messageController.add('${item.user} : ${item.text}');
        }
      else if(data.message != null) {
        setState(() {
          messages.add(data.message ?? Message());
        });
        animateToEndOfChat();
      }

    });
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      // After the first frame, add a listener to detect when the keyboard is fully visible
      _addKeyboardListener();
    });
    super.initState();
  }

  void _addKeyboardListener() {
    final double viewInsetsBottom = WidgetsBinding.instance!.window.viewInsets.bottom;
    if (viewInsetsBottom > 0) {
      // Keyboard is already visible, scroll to the end of the ListView
      animateToEndOfChat();
    } else {
      // Keyboard is not yet visible, add a listener to detect when it becomes visible
      WidgetsBinding.instance!.addObserver(_KeyboardVisibilityObserver(
        onKeyboardVisible: animateToEndOfChat,
      ));
    }
  }



  void animateToEndOfChat(){
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(scrollController.hasClients){
        scrollController.animateTo(scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.bounceIn);
      }
    });

  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(_KeyboardVisibilityObserver());
    _channel.sink.close();
    super.dispose();
  }

  void _sendMessage() {
    final MessageModel message = MessageModel(text: _messageController.text,
      token: token,);
    _channel.sink.add(json.encode(message));
    _messageController.clear();
  }

  Future<void> _getToken() async {

    //check name
    if(_nameController.text.isEmpty)
      {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('enter your name!'),
        ));
        return;
      }

    final response = await http.get(Uri.parse('http://192.168.54.151:3000/token?name=${_nameController.text}'));
    if (response.statusCode == 200) {
      print(response.body);
      setState(() {
        token = TokenModel.fromJson(json.decode(response.body)).token!;
        isConnected = true;
      });
      animateToEndOfChat();

    } else {
      print(response.statusCode);
      throw Exception('Failed to get token');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          
          children: <Widget>[
            Text(
              'WebSocket Chat',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            if(isConnected)
            Expanded(
              child: Column(
                children: [
                  Text(
                    'hello ${_nameController.text}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.only(bottom: 30),
                      itemCount: messages.length,
                      controller: scrollController,
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      itemBuilder: (BuildContext context, int index) { 
                      return Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            Text('${messages[index].user}: ', style: TextStyle(fontWeight: FontWeight.w700),),
                            Text(messages[index].text?? ''),
                          ],
                        ),
                      );
                    },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          focusNode: _focusNode,
                          controller: _messageController,
                          onSubmitted: (_)=>_sendMessage(),
                          decoration: const InputDecoration(labelText: 'Enter your message',),
                        ),
                      ),
                      IconButton(onPressed: _sendMessage, icon: Icon(Icons.send),),
                    ],
                  ),
                ],
              ),
            )
            else
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Enter your name'),
                  ),
                    ElevatedButton(
                      onPressed: () {
                        _getToken();
                      },
                      child: Text('connect'),
                    ),
                  ],
                ),
              )

          ],
        ),
      ),
    );
  }

}


class _KeyboardVisibilityObserver extends WidgetsBindingObserver {
  final VoidCallback onKeyboardVisible;

  _KeyboardVisibilityObserver({this.onKeyboardVisible = _defaultCallback});

  static void _defaultCallback() {}

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    final double viewInsetsBottom = WidgetsBinding.instance!.window.viewInsets.bottom;
    if (viewInsetsBottom > 0) {
      // Keyboard is fully visible, invoke the callback
      onKeyboardVisible();
    }
  }
}