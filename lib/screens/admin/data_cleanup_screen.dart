// lib/screens/admin/data_cleanup_screen.dart
import 'package:flutter/material.dart';
import '../../services/inventory_service.dart';
import '../../services/user_service.dart';

class DataCleanupScreen extends StatefulWidget {
  const DataCleanupScreen({super.key});

  @override
  State<DataCleanupScreen> createState() => _DataCleanupScreenState();
}

class _DataCleanupScreenState extends State<DataCleanupScreen> {
  static const Color primaryColor = Color(0xFF6C63FF);
  bool _isRunning = false;
  String? _resultMessage;

  Future<void> _runCleanup() async {
    setState(() {
      _isRunning = true;
      _resultMessage = null;
    });

    try {
      final inventoryDeleted = await InventoryService()
          .cleanupOrphanedInventory();

      setState(() {
        _resultMessage =
            'Cleanup complete!\n$inventoryDeleted orphaned inventory record(s) removed.\n\n'
            'Note: Transaction history is kept permanently for audit purposes, '
            'even for deleted components.';
      });
    } catch (e) {
      setState(() => _resultMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  // State class mein naya method:
  Future<void> _rebuildIndex() async {
    setState(() {
      _isRunning = true;
      _resultMessage = null;
    });

    try {
      final fixed = await UserService().rebuildEmployeeIndex();
      setState(() {
        _resultMessage =
            'Employee ID index rebuilt!\n$fixed missing entr${fixed == 1 ? 'y' : 'ies'} created.';
      });
    } catch (e) {
      setState(() => _resultMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Data Cleanup'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cleaning_services_outlined,
                        color: primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Orphaned Data Cleanup',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'If a component was deleted directly from Firestore Console '
                    '(instead of using the app\'s Delete button), its inventory '
                    'and transaction records may still remain, causing incorrect '
                    'stock totals on the dashboard. Run this to remove those '
                    'leftover records.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                icon: _isRunning
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_arrow, color: Colors.white),
                label: Text(
                  _isRunning ? 'Running...' : 'Run Cleanup',
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: _isRunning ? null : _runCleanup,
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.badge_outlined),
                label: const Text('Rebuild Employee ID Index'),
                onPressed: _isRunning ? null : _rebuildIndex,
              ),
            ),
            if (_resultMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _resultMessage!,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
