import 'package:air_mind/widgets/code_element_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/services.dart';

// A MessageBubble for showing a single chat message on the ChatScreen.
class MessageBubble extends StatelessWidget {
  // Create a message bubble which is meant to be the first in the sequence.
  const MessageBubble.first({
    super.key,
    required this.message,
    required this.isMe,
  }) : isFirstInSequence = true;

  // Create a message bubble that continues the sequence.
  const MessageBubble.next({
    super.key,
    required this.message,
    required this.isMe,
  }) : isFirstInSequence = false;

  final bool isFirstInSequence;
  final String message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onLongPress: () {
        // copy message to clipboard
        Clipboard.setData(ClipboardData(text: message));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message copied to clipboard.'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: Row(
        // The side of the chat screen the message should show at.
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (isFirstInSequence) const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.grey[300]
                  : theme.colorScheme.tertiary.withAlpha(50),
              borderRadius: BorderRadius.only(
                topLeft: !isMe && isFirstInSequence
                    ? Radius.zero
                    : const Radius.circular(12),
                topRight: isMe && isFirstInSequence
                    ? Radius.zero
                    : const Radius.circular(12),
                bottomLeft: const Radius.circular(12),
                bottomRight: const Radius.circular(12),
              ),
            ),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: MarkdownBody(
              data: message,
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(
                  height: 1.3,
                  color: theme.colorScheme.onSurface,
                ),
                h1: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                h2: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                tableHead: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                tableColumnWidth:
                    FixedColumnWidth(MediaQuery.of(context).size.width * 0.5),
                tableCellsDecoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
              softLineBreak: true,
              builders: {
                'code': CodeElementBuilder(),
              },
            ),
          ),
        ],
      ),
    );
  }
}
