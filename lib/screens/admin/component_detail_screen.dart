// lib/screens/admin/component_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:internshiptask/models/transaction_model.dart';
import 'package:internshiptask/screens/admin/edit_component_screen.dart';
import 'package:internshiptask/screens/component_transaction_history_screen.dart';
import 'package:internshiptask/services/transaction_service.dart';
import '../../models/component_model.dart';
import '../../models/inventory_model.dart';
import '../../models/location_model.dart';
import '../../services/inventory_service.dart';
import '../../services/location_service.dart';
import 'stock_action_dialog.dart';
import 'transfer_dialog.dart';

class ComponentDetailScreen extends StatelessWidget {
  final ComponentModel component;
  const ComponentDetailScreen({super.key, required this.component});

  static const Color primaryColor = Color(0xFF6C63FF);

  Color _classColor(String cls) {
    switch (cls) {
      case 'A':
        return Colors.red;
      case 'B':
        return Colors.blue;
      case 'C':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Sensor':
        return Icons.sensors;
      case 'IC (Integrated Circuit)':
        return Icons.memory;
      case 'Resistor':
      case 'Capacitor':
      case 'Inductor':
      case 'Diode':
      case 'Transistor':
        return Icons.electrical_services;
      case 'Connector':
      case 'Cable/Wire':
        return Icons.cable;
      case 'Switch':
      case 'Relay':
        return Icons.toggle_on_outlined;
      case 'PCB':
        return Icons.developer_board;
      default:
        return Icons.category_outlined;
    }
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$feature — coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final inventoryService = InventoryService();
    final locationService = LocationService();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: StreamBuilder<List<InventoryModel>>(
        stream: inventoryService.getInventoryForComponent(component.id),
        builder: (context, snapshot) {
          final records = snapshot.data ?? [];
          final totalQty = records.fold<int>(0, (sum, r) => sum + r.quantity);
          final totalDamaged = records.fold<int>(
            0,
            (sum, r) => sum + r.damagedQuantity,
          );
          final isOutOfStock = totalQty == 0;
          final isLowStock =
              !isOutOfStock && totalQty <= component.minimumStock;

          final statusColor = isOutOfStock
              ? Colors.red
              : isLowStock
              ? Colors.orange
              : Colors.green;
          final statusLabel = isOutOfStock
              ? 'Out of Stock'
              : isLowStock
              ? 'Low Stock'
              : 'Available';

          return CustomScrollView(
            slivers: [
              // Image header with back + edit
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, size: 18),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_outlined, size: 18),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              EditComponentScreen(component: component),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: component.imageUrls.isEmpty
                      ? Container(
                          color: const Color(0xFFF0F0F5),
                          child: Center(
                            child: Icon(
                              _iconForType(component.type),
                              size: 72,
                              color: Colors.grey[400],
                            ),
                          ),
                        )
                      : _ImageCarousel(imageUrls: component.imageUrls),
                ),
              ),

              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name + class
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                component.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _classColor(
                                  component.abcdClass,
                                ).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'CLASS ${component.abcdClass}',
                                style: TextStyle(
                                  color: _classColor(component.abcdClass),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          component.type,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          component.componentCode,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Status + Total Stock row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'STATUS',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          statusLabel,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'TOTAL STOCK',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$totalQty units',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Stock Overview
                        _sectionTitle('STOCK OVERVIEW'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            children: [
                              _statRow(
                                'Minimum Stock',
                                '${component.minimumStock}',
                              ),
                              const Divider(height: 18),
                              _statRow(
                                'Available',
                                '$totalQty',
                                color: statusColor,
                              ),
                              const Divider(height: 18),
                              _statRow(
                                'Damaged',
                                '$totalDamaged',
                                color: totalDamaged > 0 ? Colors.red : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Physical Locations
                        _sectionTitle('PHYSICAL LOCATIONS'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: records.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text(
                                    'No stock recorded yet.',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: records.map((r) {
                                    return FutureBuilder<List<LocationModel>>(
                                      future: locationService.getFullPath(
                                        r.locationId,
                                      ),
                                      builder: (context, pathSnap) {
                                        final path = pathSnap.data ?? [];
                                        final pathText = path
                                            .map((l) => '${l.type} ${l.name}')
                                            .join(' → ');
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 10,
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.place_outlined,
                                                size: 16,
                                                color: primaryColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      pathText.isEmpty
                                                          ? 'Locating...'
                                                          : pathText,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Quantity: ${r.quantity}',
                                                      style: const TextStyle(
                                                        fontSize: 12,
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
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Component Information
                        _sectionTitle('COMPONENT INFORMATION'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _infoBlock(
                                      'MANUFACTURER',
                                      component.manufacturer,
                                    ),
                                  ),
                                  Expanded(
                                    child: _infoBlock(
                                      'PART NUMBER',
                                      component.partNumber,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _infoBlock(
                                      'CATEGORY',
                                      component.type,
                                    ),
                                  ),
                                  Expanded(child: _infoBlock('UNIT', 'Pcs')),
                                ],
                              ),
                              if (component.description.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                _infoBlock(
                                  'DESCRIPTION',
                                  component.description,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Actions
                        _sectionTitle('ACTIONS'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Add Stock',
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
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.arrow_upward, size: 18),
                                label: const Text('Issue'),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => StockActionDialog(
                                    component: component,
                                    action: StockAction.remove,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.arrow_downward,
                                  size: 18,
                                ),
                                label: const Text('Return'),
                                onPressed: () => showDialog(
                                  context: context,
                                  builder: (_) => StockActionDialog(
                                    component: component,
                                    action: StockAction.add,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(Icons.swap_horiz, size: 18),
                                label: const Text('Transfer'),
                                onPressed: () async {
                                  await showDialog(
                                    context: context,
                                    builder: (_) =>
                                        TransferDialog(component: component),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
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
                        ),
                        const SizedBox(height: 16),

                        // Recent Transactions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionTitle('RECENT TRANSACTIONS'),
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ComponentTransactionHistoryScreen(
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
                        StreamBuilder<List<TransactionModel>>(
                          stream: TransactionService()
                              .getTransactionsForComponent(
                                component.id,
                                limit: 5,
                              ),
                          builder: (context, snapshot) {
                            final txns = snapshot.data ?? [];
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
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
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
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
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
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _statRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _infoBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 3),
        Text(
          value.isEmpty ? '—' : value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// 👇 Naya widget — file ke end mein, class ke bahar
class _ImageCarousel extends StatefulWidget {
  final List<String> imageUrls;
  const _ImageCarousel({required this.imageUrls});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _currentIndex = 0;
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          itemCount: widget.imageUrls.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            return Image.network(
              widget.imageUrls[index],
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  color: const Color(0xFFF0F0F5),
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF0F0F5),
                  child: const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            );
          },
        ),

        // Dots indicator — agar 1 se zyada image ho
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentIndex == index ? 8 : 6,
                  height: _currentIndex == index ? 8 : 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? Colors.white
                        : Colors.white54,
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}
