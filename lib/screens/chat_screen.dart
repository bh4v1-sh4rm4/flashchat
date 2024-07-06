import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flashchat/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final _firestore = FirebaseFirestore.instance;

class ChatScreen extends StatefulWidget {
  static var id = 'chat_screen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final fieldText = TextEditingController();
  late User loggedInUser;
  late String messageText;
  // @override
  // void initState() {
  //   getCurretnUser();
  //   print("current user $loggedInUser");
  //   super.initState();
  // }

  void getCurrentUser() {
    var currentUser = _auth.currentUser;
    try {
      if (currentUser != null) {
        loggedInUser = currentUser;
      }
    } catch (e) {
      print(e);
    }
  }

  // void getMessages() async {
  //   final recievedMessages = await _firestore.collection("messages").get();
  // for (var message in recievedMessages.docs) {
  //   print(message.data());
  // }
  // }

  void messageStream() async {
    await for (var snapshot in _firestore.collection("messages").snapshots()) {
      for (var message in snapshot.docs) {
        print(message.data());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    getCurrentUser();
    print('current user ${_auth.currentUser!.email}');
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
                // messageStream();
              }),
        ],
        title: const Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection("messages")
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                print('snapshot data ${snapshot.data!.docs}');
                if (!snapshot.hasData) {
                  return const Center(
                      child: Text('Start a new chat by sending first message'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                return Expanded(
                  child: ListView(
                    reverse: true,
                    children: snapshot.data!.docs
                        .map((DocumentSnapshot document) {
                          Map<String, dynamic> data =
                              document.data()! as Map<String, dynamic>;
                          var messageSender = data['sending_user'];
                          var currentUser = loggedInUser.email;
                          print('meassage data $data');
                          print("messaeg text ${data['sending_user']}");
                          print("messaeg timestamp ${data['timestamp']}");
                          print(data['messageText']);
                          return MessageBubble(
                              data['messageText'],
                              data['sending_user'],
                              data['timestamp'],
                              currentUser == messageSender);

                          // null;
                        })
                        .toList()
                        .cast(),
                  ),
                );
              },
            ),
            Container(
              decoration: kMessageContainerDecoration,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      onChanged: (value) {
                        messageText = value;
                      },
                      decoration: kMessageTextFieldDecoration,
                      controller: fieldText,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      //message text + user email id
                      var timestamp =
                          DateTime.now().millisecondsSinceEpoch.toString();
                      _firestore.collection('messages').add({
                        'messageText': messageText,
                        'sending_user': loggedInUser.email,
                        'timestamp': timestamp
                      });
                      print('message $messageText');
                      print('sending_user ${loggedInUser.email}');
                      print('timestamp $timestamp');
                      fieldText.clear();
                    },
                    child: const Text(
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

class MessageBubble extends StatelessWidget {
  MessageBubble(this.message, this.sender, this.timestamp, this.isMe);
  final String message;
  final String sender;
  final String timestamp;
  final bool isMe;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: Text(
              sender,
              style: const TextStyle(fontSize: 10),
            ),
          ),
          Material(
            borderRadius: isMe
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                  )
                : const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
            elevation: 5,
            color: isMe ? Colors.lightBlueAccent : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Text(
                message,
                textAlign: TextAlign.start,
                style: isMe
                    ? const TextStyle(color: Colors.white, fontSize: 16)
                    : const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
          ),
        ],
        // title: Text(data['messageText'],\
        // subtitle: Text(data['sending_user']),
      ),
    );
  }
}
