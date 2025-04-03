import 'package:flutter/material.dart';

class ConnectionInfo extends StatelessWidget {
  const ConnectionInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Info',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'If you maintain an IP whitelist, you may need to whitelist the MindsDB static IPs:',
            ),
            const SizedBox(height: 8),
            // Using SelectableText to make IP addresses copyable
            const SelectableText('23.21.189.110'),
            const SelectableText('44.223.158.176'),
            const SizedBox(height: 20),
            // Adding OK button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
