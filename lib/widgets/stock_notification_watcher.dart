// lib/widgets/stock_notification_watcher.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/component_model.dart';
import '../models/inventory_model.dart';
import '../models/notification_model.dart';
import '../services/component_service.dart';
import '../services/inventory_service.dart';
import '../services/local_notification_service.dart';
import '../services/notification_service.dart';

class StockNotificationWatcher extends StatefulWidget {
  final Widget child;
  const StockNotificationWatcher({super.key, required this.child});

  @override
  State<StockNotificationWatcher> createState() =>
      _StockNotificationWatcherState();
}

class _StockNotificationWatcherState extends State<StockNotificationWatcher> {
  final _componentService = ComponentService();
  final _inventoryService = InventoryService();
  final _notificationService = LocalNotificationService();
  final _notificationServiceFirestore = NotificationService();

  StreamSubscription<List<ComponentModel>>? _componentSub;
  StreamSubscription<List<InventoryModel>>? _inventorySub;

  List<ComponentModel>? _components;
  List<InventoryModel>? _inventory;

  Set<String> _lowStockIds = {};
  Set<String> _outOfStockIds = {};

  Set<String> _knownComponentIds = {};

  @override
  void initState() {
    super.initState();
    _componentSub = _componentService.getComponents().listen((comps) {
      _components = comps;
      _checkStockLevels();
    });
    _inventorySub = _inventoryService.getAllInventory().listen((inv) {
      _inventory = inv;
      _checkStockLevels();
    });
  }

  @override
  void dispose() {
    _componentSub?.cancel();
    _inventorySub?.cancel();
    super.dispose();
  }

  ComponentModel? _findComponent(String id) {
    if (_components == null) return null;
    for (var c in _components!) {
      if (c.id == id) return c;
    }
    return null;
  }

  void _checkStockLevels() {
    if (_components == null || _inventory == null) return;

    final qtyMap = <String, int>{};
    for (var rec in _inventory!) {
      qtyMap[rec.componentId] = (qtyMap[rec.componentId] ?? 0) + rec.quantity;
    }

    final newLow = <String>{};
    final newOut = <String>{};

    for (var c in _components!) {
      final q = qtyMap[c.id] ?? 0;
      if (q == 0) {
        newOut.add(c.id);
      } else if (q <= c.minimumStock) {
        newLow.add(c.id);
      }
    }

    final newlyOut = newOut
        .difference(_outOfStockIds)
        .intersection(_knownComponentIds);
    for (var id in newlyOut) {
      final comp = _findComponent(id);
      if (comp != null) {
        _notificationService.show(
          id: comp.id.hashCode,
          title: '🔴 Out of Stock',
          body: '${comp.name} (${comp.componentCode}) is now out of stock.',
        );
        _notificationServiceFirestore.createNotification(
          NotificationModel(
            id: '',
            title: 'Out of Stock',
            body: '${comp.name} (${comp.componentCode}) is now out of stock.',
            type: 'out_of_stock',
            componentId: comp.id,
          ),
        );
      }
    }

    final newlyLow = newLow
        .difference(_lowStockIds)
        .difference(newOut)
        .intersection(_knownComponentIds);
    for (var id in newlyLow) {
      final comp = _findComponent(id);
      if (comp != null) {
        _notificationService.show(
          id: comp.id.hashCode,
          title: '⚠️ Low Stock Alert',
          body: '${comp.name} (${comp.componentCode}) is running low.',
        );
        _notificationServiceFirestore.createNotification(
          NotificationModel(
            id: '',
            title: 'Low Stock Alert',
            body: '${comp.name} (${comp.componentCode}) is running low.',
            type: 'low_stock',
            componentId: comp.id,
          ),
        );
      }
    }

    _lowStockIds = newLow;
    _outOfStockIds = newOut;

    _knownComponentIds = _components!.map((c) => c.id).toSet();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
