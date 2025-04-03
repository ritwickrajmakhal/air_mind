import 'package:air_mind/widgets/chat_messages.dart';
import 'package:air_mind/widgets/main_drawer.dart';
import 'package:air_mind/widgets/new_message.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:air_mind/widgets/chat_box_fallback.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _threads;
  final userId = FirebaseAuth.instance.currentUser!.uid;
  String? _activeThreadId;
  String _title = 'New Chat';
  String _shortCommand = '';

  @override
  void initState() {
    super.initState();
    _threads = FirebaseFirestore.instance
        .collection('threads')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    Widget chatBox = ChatBoxFallback(onTapShortCommand: (command) {
      if (command != _shortCommand) {
        setState(() {
          _shortCommand = command;
        });
      }
    });

    if (_activeThreadId != null) {
      chatBox = ChatMessages(activeThreadId: _activeThreadId!);
    }

    return Scaffold(
      drawer: MainDrawer(
        threads: _threads,
        onSelectThread: (String threadId) async {
          if (_activeThreadId != threadId) {
            final thread = await FirebaseFirestore.instance
                .collection('threads')
                .doc(threadId)
                .get();
            setState(() {
              _activeThreadId = threadId;
              _title = thread.data()!['title'];
            });
            _shortCommand = '';
          }
          Navigator.of(context).pop();
        },
        onDeleteThread: (String threadId) {
          // Delete a thread, if it's the active thread, reset the active thread and close the drawer
          if (threadId == _activeThreadId) {
            setState(() {
              _activeThreadId = null;
              _title = 'New Chat';
            });
            Navigator.of(context).pop();
          }
          FirebaseFirestore.instance
              .collection('threads')
              .doc(threadId)
              .delete();
        },
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(_title),
        actions: [
          IconButton(
            onPressed: () {
              if (_activeThreadId != null) {
                setState(() {
                  _activeThreadId = null;
                  _title = 'New Chat';
                });
              }
            },
            icon: Icon(
              Icons.add_comment_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatBox,
          ),
          NewMessage(
            shortCommand: _shortCommand,
            onShortCommandUsed: () {
              if (_shortCommand.isNotEmpty) {
                setState(() {
                  _shortCommand = '';
                });
              }
            },
            activeThreadId: _activeThreadId,
            onCreateNewThread: (String threadId) async {
              final thread = await FirebaseFirestore.instance
                  .collection('threads')
                  .doc(threadId)
                  .get();
              setState(() {
                _activeThreadId = threadId;
                _title = thread.data()!['title'];
              });
            },
          )
        ],
      ),
    );
  }
}
