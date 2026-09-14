// lib/screens/lab_staff/lab_staff_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/component_model.dart';
import '../../models/inventory_model.dart';
import '../../models/transaction_model.dart';
import '../../models/notification_model.dart';
import '../../services/component_service.dart';
import '../../services/inventory_service.dart';
import '../../services/transaction_service.dart';
import '../../services/notification_service.dart';
import 'lab_staff_search_screen.dart';
import 'lab_staff_component_detail_screen.dart';
import '../notifications_screen.dart';

class LabStaffHomeScreen extends StatefulWidget {
  const LabStaffHomeScreen({super.key});

  @override
  State<LabStaffHomeScreen> createState() => _LabStaffHomeScreenState();
}

class _LabStaffHomeScreenState extends State<LabStaffHomeScreen> {
  static const Color primaryColor = Color(0xFF6C63FF);
  final _searchController = TextEditingController();

  void _goToSearch([String query = '']) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LabStaffSearchScreen(initialQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final componentService = ComponentService();
    final inventoryService = InventoryService();
    final transactionService = TransactionService();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'WELCOME BACK',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Good day, ${user?.name ?? 'there'}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                // 👇 Bell icon — sirf ye ek jagah notifications dikhata hai
                StreamBuilder<List<NotificationModel>>(
                  stream: NotificationService().getRecentNotifications(
                    limit: 10,
                  ),
                  builder: (context, snapshot) {
                    final count = snapshot.data?.length ?? 0;
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                        if (count > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primaryColor.withValues(alpha: 0.15),
                  child: Text(
                    user != null && user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'What component are you looking for?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, code or part no.',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onSubmitted: (val) => _goToSearch(val),
            ),
            const SizedBox(height: 24),

            // 👇 Recently Used — ab real data, sirf current user ki
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENTLY USED',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (user == null)
              const SizedBox.shrink()
            else
              StreamBuilder<List<TransactionModel>>(
                stream: transactionService.getTransactionsForUser(
                  user.id,
                  limit: 20,
                ),
                builder: (context, snapshot) {
                  final allTxns = snapshot.data ?? [];
                  final issuedTxns = allTxns
                      .where((t) => t.type == TransactionType.issue)
                      .take(3)
                      .toList();

                  if (issuedTxns.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'No components used yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    );
                  }

                  return SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: issuedTxns.length,
                      itemBuilder: (context, index) {
                        final txn = issuedTxns[index];
                        return FutureBuilder<ComponentModel?>(
                          future: componentService.getComponent(
                            txn.componentId,
                          ),
                          builder: (context, compSnap) {
                            final comp = compSnap.data;
                            return GestureDetector(
                              onTap: comp == null
                                  ? null
                                  : () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              LabStaffComponentDetailScreen(
                                                component: comp,
                                              ),
                                        ),
                                      );
                                    },
                              child: Container(
                                width: 130,
                                margin: const EdgeInsets.only(right: 10),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.memory,
                                      color: primaryColor,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      txn.componentName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '${txn.quantity} issued',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),

            const Text(
              'AVAILABILITY ALERTS',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),

            StreamBuilder<List<ComponentModel>>(
              stream: componentService.getComponents(),
              builder: (context, compSnap) {
                final components = compSnap.data ?? [];
                return StreamBuilder<List<InventoryModel>>(
                  stream: inventoryService.getAllInventory(),
                  builder: (context, invSnap) {
                    final inventory = invSnap.data ?? [];
                    final qtyMap = <String, int>{};
                    for (var rec in inventory) {
                      qtyMap[rec.componentId] =
                          (qtyMap[rec.componentId] ?? 0) + rec.quantity;
                    }

                    final alerts = components
                        .where((c) {
                          final q = qtyMap[c.id] ?? 0;
                          return q <= c.minimumStock;
                        })
                        .take(3)
                        .toList();

                    if (alerts.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'All components are sufficiently stocked.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      );
                    }

                    return Column(
                      children: alerts.map((c) {
                        final q = qtyMap[c.id] ?? 0;
                        final isOut = q == 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${c.name} is ${isOut ? "Out of Stock" : "Low on Stock"}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      isOut
                                          ? 'No units currently available.'
                                          : 'Only $q left (min ${c.minimumStock}).',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
