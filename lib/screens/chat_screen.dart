import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firestore = Firestore.instance;
FirebaseUser loggedInUser;

class ChatScreen extends StatefulWidget {
  static String routeId = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;


  String messageText;
  var _textController = TextEditingController();

  void getCurrentUser() async {
    try {
      final user = await _auth.currentUser();
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser.email);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.close),
              onPressed: () {
                //Implement logout functionality
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MessageStream(),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      onChanged: (value) {
                        //Do something with the user input.
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                    ),
                  ),
                  FlatButton(
                    onPressed: () {
                      //Implement send functionality.
                      _firestore.collection('messages').add(
                          {'text': messageText, 'sender': loggedInUser.email, 'time' : DateTime.now().millisecondsSinceEpoch});
                      _textController.clear();
                    },
                    child: Text(
                      'Send',
                      style: kSendButtonTextStyle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MessageStream extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('messages').orderBy('time').snapshots(),
      builder: (context, snapshot) {
        List<MessageBubble> textWidgets = [];
        if (!snapshot.hasData) {
          return Center(
            child: Container(
              margin: EdgeInsets.only(top: 50),
              height: 50.0,
              width: 50.0,
              child: CircularProgressIndicator(
                backgroundColor: Colors.yellowAccent,
              ),
            ),
          );
        }
        final messages = snapshot.data.documents;
        for (var message in snapshot.data.documents.reversed) {
          textWidgets
              .add(MessageBubble(
                message.data['text'],
                message.data['sender'],
                isMe: message.data['sender'] == loggedInUser.email,));
        }
        return
           Expanded(
             child: ListView(
               reverse: true,
               padding: EdgeInsets.all(10.0),
              children: textWidgets,
             ),
           );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  MessageBubble(this.message, this.from, {@required this.isMe});

  final String message;
  final String from;
  final bool isMe;

  final borderRadius = 20.0;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(from, style: TextStyle(color: Colors.white30),),
          SizedBox(height: 2.0,),
          Material(
            borderRadius: BorderRadius.only(topLeft: isMe ? Radius.circular(borderRadius) : Radius.zero, topRight: Radius.circular(borderRadius), bottomRight: isMe ? Radius.zero : Radius.circular(borderRadius), bottomLeft: Radius.circular(borderRadius)),
            elevation: 4.0,
            color: isMe ? Colors.blueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
              child: Text(
                message,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 16.0
              ),
          ),
            )),
        ],
      ),
    );
  }
}
