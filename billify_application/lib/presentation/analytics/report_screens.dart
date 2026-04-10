import 'package:flutter/material.dart';



class InventoryReportsScreen extends StatelessWidget {
  const InventoryReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Reports')),
      body: const Center(child: Text('Detailed Inventory Reports coming soon!')),
    );
  }
}

// Note: CustomerReportsScreen and KhataReportsScreen are now imported from their own feature directories

class PaymentReportsScreen extends StatelessWidget {
  const PaymentReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Reports')),
      body: const Center(child: Text('Detailed Payment Reports coming soon!')),
    );
  }
}
