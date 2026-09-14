// lib/screens/lab_staff/lab_staff_component_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:internshiptask/screens/component_transaction_history_screen.dart';
import '../../models/component_model.dart';
import '../../models/inventory_model.dart';
import '../../models/location_model.dart';
import '../../models/transaction_model.dart'; // 👈 naya import
import '../../services/inventory_service.dart';
import '../../services/location_service.dart';
import '../../services/transaction_service.dart'; // 👈 naya import
import '../admin/stock_action_dialog.dart';

class LabStaffComponentDetailScreen extends StatelessWidget {
  final ComponentModel component;
  const LabStaffComponentDetailScreen({super.key, required this.component});

  static const Color primaryColor = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    final inventoryService = InventoryService();
    final locationService = LocationService();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: Text(component.name),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<InventoryModel>>(
        stream: inventoryService.getInventoryForComponent(component.id),
        builder: (context, snapshot) {
          final records = snapshot.data ?? [];
          final totalQty = records.fold<int>(0, (sum, r) => sum + r.quantity);
          final isOut = totalQty == 0;
          final isLow = !isOut && totalQty <= component.minimumStock;
          final statusColor = isOut
              ? Colors.red
              : (isLow ? Colors.orange : Colors.green);
          final statusLabel = isOut
              ? 'Out of Stock'
              : (isLow ? 'Low Stock' : 'Available');

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      component.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      component.componentCode,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 8, color: statusColor),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$totalQty units',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Physical Locations',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (records.isEmpty)
                      const Text(
                        'No stock recorded yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      )
                    else
                      ...records.map(
                        (r) => FutureBuilder<List<LocationModel>>(
                          future: locationService.getFullPath(r.locationId),
                          builder: (context, pathSnap) {
                            final path = pathSnap.data ?? [];
                            final pathText = path
                                .map((l) => '${l.type} ${l.name}')
                                .join(' → ');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.place_outlined,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      pathText.isEmpty
                                          ? 'Locating...'
                                          : pathText,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '${r.quantity} pcs',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Lab staff sirf Issue, Return, Damage kar sakta hai (Add Component/Delete nahi)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      icon: const Icon(
                        Icons.arrow_upward,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Issue',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => StockActionDialog(
                          component: component,
                          action: StockAction.remove,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      icon: const Icon(
                        Icons.arrow_downward,
                        color: Colors.white,
                        size: 18,
                      ),
                      label: const Text(
                        'Return',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => StockActionDialog(
                          component: component,
                          action: StockAction.add,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                icon: const Icon(
                  Icons.warning_amber,
                  size: 16,
                  color: Colors.red,
                ),
                label: const Text(
                  'Mark Damaged',
                  style: TextStyle(color: Colors.red, fontSize: 13),
                ),
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => StockActionDialog(
                    component: component,
                    action: StockAction.damage,
                  ),
                ),
              ),

              // 👇 YAHAN ADD KARNA HAI — "Mark Damaged" button ke bilkul neeche
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'RECENT TRANSACTIONS',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ComponentTransactionHistoryScreen(
                            componentId: component.id,
                            componentName: component.name,
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'View History',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<TransactionModel>>(
                stream: TransactionService().getTransactionsForComponent(
                  component.id,
                  limit: 5,
                ),
                builder: (context, txnSnapshot) {
                  final txns = txnSnapshot.data ?? [];
                  if (txns.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'No transactions recorded yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    );
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: txns.map((t) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${t.userName} ${TransactionModel.typeToString(t.type)}d ${t.quantity} units',
                                  style: const TextStyle(fontSize: 12),
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
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              // 👆 yahan tak
            ],
          );
        },
      ),
    );
  }
}
