import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:mdb_dart/mdb_dart.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final client = Client(dotenv.env['MINDS_API_KEY']!);

class NewMessage extends StatefulWidget {
  const NewMessage({
    super.key,
    required this.activeThreadId,
    required this.onCreateNewThread,
    required this.shortCommand,
    required this.onShortCommandUsed,
  });

  final String? activeThreadId;
  final void Function(String threadId) onCreateNewThread;
  final String shortCommand;
  final void Function() onShortCommandUsed;

  @override
  State<NewMessage> createState() => NewMessageState();
}

class NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitMessage() async {
    final enteredMessage = _messageController.text;

    // Early validation check
    if (enteredMessage.trim().isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
    });

    // Clear input immediately for better UX
    _messageController.clear();
    widget.onShortCommandUsed();

    // Get user ID once
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final timestamp = Timestamp.now();

    try {
      if (widget.activeThreadId == null) {
        // Create a new thread
        final newThread = await FirebaseFirestore.instance
            .collection('threads')
            .add({
          'title': enteredMessage,
          'userId': userId,
          'createdAt': timestamp
        });

        // Notify parent about new thread
        widget.onCreateNewThread(newThread.id);
        // Add message to the new thread
        await FirebaseFirestore.instance
            .collection('threads')
            .doc(newThread.id)
            .collection('chats')
            .add({
          'userId': userId,
          'createdAt': timestamp,
          'text': enteredMessage
        });
      } else {
        // Add message to existing thread
        await FirebaseFirestore.instance
            .collection('threads')
            .doc(widget.activeThreadId)
            .collection('chats')
            .add({
          'userId': userId,
          'createdAt': timestamp,
          'text': enteredMessage
        });
      }

      // Ask to mind
      Mind? mind;
      try {
        mind = await client.minds.get(userId);
      } catch (error) {
        if (error.toString().contains('Mind not found')) {
          mind = await client.minds.create(
            name: userId,
            datasources: [userId],
            replace: true,
          );
        }
      }
      final completion = await mind!.completion(enteredMessage);

      // Save the complete AI response
      if (widget.activeThreadId != null) {
        await FirebaseFirestore.instance
            .collection('threads')
            .doc(widget.activeThreadId)
            .collection('chats')
            .add({
          'userId': 'ai', // Use a special ID to identify AI messages
          'createdAt': Timestamp.now(),
          'text': completion.choices.first.message.content?.first.text
        });
      }
    } catch (error) {
      if (error.toString().contains('Datasource not found')) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Datasource not found. Please create a new one.')));
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _messageController.text = widget.shortCommand;

    return Container(
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              textCapitalization: TextCapitalization.sentences,
              autocorrect: true,
              enableSuggestions: true,
              minLines: 1,
              maxLines: 4, // Allows for expansion up to 4 lines
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Ask me anything...',
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
            ),
          ),
          if (!_loading)
            IconButton(
              onPressed: _submitMessage,
              icon: Icon(
                Icons.arrow_circle_up,
                color: Theme.of(context).colorScheme.primary,
                size: 35,
              ),
            ),
          if (_loading)
            LoadingAnimationWidget.waveDots(
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
        ],
      ),
    );
  }
}
