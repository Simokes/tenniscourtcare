// filepath: lib/presentation/screens/stock_history_screen.dart

import 'package:flutter/material.dart';

class StockHistoryScreen extends StatelessWidget {
  const StockHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock History')),
      body: const Center(
        child: Text('Stock History Screen'),
      ),
    );
  }
}
