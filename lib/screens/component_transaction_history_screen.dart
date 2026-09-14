// lib/screens/component_transaction_history_screen.dart
import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/transaction_service.dart';

class ComponentTransactionHistoryScreen extends StatelessWidget {
  final String componentId;
  final String componentName;

  const ComponentTransactionHistoryScreen({
    super.key,
    required this.componentId,
    required this.componentName,
  });

  static const Color primaryColor = Color(0xFF6C63FF);

  IconData _iconFor(TransactionType t) {
    switch (t) {
      case TransactionType.issue:
        return Icons.arrow_upward;
      case TransactionType.returned:
        return Icons.arrow_downward;
      case TransactionType.restock:
        return Icons.add_box_outlined;
      case TransactionType.damage:
        return Icons.warning_amber;
      case TransactionType.transfer:
        return Icons.swap_horiz;
    }
  }

  Color _colorFor(TransactionType t) {
    switch (t) {
      case TransactionType.issue:
        return Colors.orange;
      case TransactionType.returned:
        return Colors.green;
      case TransactionType.restock:
        return Colors.blue;
      case TransactionType.damage:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = TransactionService();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: Text('$componentName — History'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: service.getTransactionsForComponent(componentId, limit: 100),
        builder: (context, snapshot) {
          final txns = snapshot.data ?? [];

          if (txns.isEmpty) {
            return const Center(
              child: Text(
                'No transactions recorded yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: txns.length,
            itemBuilder: (context, index) {
              final t = txns[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _colorFor(t.type).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _iconFor(t.type),
                        color: _colorFor(t.type),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${t.userName} — ${TransactionModel.typeToString(t.type)}d ${t.quantity} units',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (t.notes != null && t.notes!.isNotEmpty)
                            Text(
                              '"${t.notes}"',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          Text(
                            t.timestamp != null
                                ? '${t.timestamp!.day}/${t.timestamp!.month}/${t.timestamp!.year}'
                                : '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
