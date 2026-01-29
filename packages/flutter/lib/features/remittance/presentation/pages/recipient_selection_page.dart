import 'package:flutter/material.dart';

/// Recipient selection page
class RecipientSelectionPage extends StatelessWidget {
  const RecipientSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Recipient'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Add new recipient
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Recipient Selection Page'),
      ),
    );
  }
}
