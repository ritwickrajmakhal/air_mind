import 'package:flutter/material.dart';

class ChatBoxFallback extends StatelessWidget {
  ChatBoxFallback({super.key, required this.onTapShortCommand});
  final void Function(String) onTapShortCommand;
  final List<Map<String, Icon>> _commands = [
    {
      'Show top items': Icon(Icons.bar_chart),
    },
    {
      'Find anomalies': Icon(Icons.warning),
    },
    {
      'Summarize data': Icon(Icons.analytics),
    },
    {
      'Compare fields': Icon(Icons.compare_arrows),
    },
    {
      'Predict trends': Icon(Icons.insights),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
        children: [
          Text(
            'What can I help with?',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24), // Add spacing between text and buttons
          Wrap(
            alignment: WrapAlignment.center, // Center the buttons
            spacing: 16, // Horizontal space between buttons
            runSpacing: 16, // Vertical space between rows
            children: _commands.map((command) {
              return ElevatedButton.icon(
                onPressed: () {
                  onTapShortCommand(command.keys.first);
                },
                icon: command.values.first,
                label: Text(command.keys.first),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(180, 48), // Consistent button size
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
