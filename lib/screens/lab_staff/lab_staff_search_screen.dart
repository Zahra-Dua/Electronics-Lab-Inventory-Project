// lib/screens/lab_staff/lab_staff_search_screen.dart
import 'package:flutter/material.dart';
import '../../models/component_model.dart';
import '../../models/inventory_model.dart';
import '../../models/location_model.dart';
import '../../services/component_service.dart';
import '../../services/inventory_service.dart';
import '../../services/location_service.dart';
import '../../constants/component_constants.dart';
import '../image_search_screen.dart';
import 'lab_staff_component_detail_screen.dart';

class LabStaffSearchScreen extends StatefulWidget {
  final String initialQuery;
  const LabStaffSearchScreen({super.key, this.initialQuery = ''});

  @override
  State<LabStaffSearchScreen> createState() => _LabStaffSearchScreenState();
}

class _LabStaffSearchScreenState extends State<LabStaffSearchScreen> {
  static const Color primaryColor = Color(0xFF6C63FF);
  final _componentService = ComponentService();
  final _inventoryService = InventoryService();
  final _locationService = LocationService();

  late TextEditingController _controller;
  String _query = '';
  String _selectedFilter = 'All';

  // 👇 Har filter ka apna icon
  static const List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'icon': Icons.apps},
    {'label': 'Available', 'icon': Icons.check_circle_outline},
    {'label': 'Low Stock', 'icon': Icons.warning_amber_outlined},
    {'label': 'Resistor', 'icon': Icons.electrical_services},
    {'label': 'Capacitor', 'icon': Icons.electrical_services},
    {'label': 'Inductor', 'icon': Icons.electrical_services},
    {'label': 'Diode', 'icon': Icons.electrical_services},
    {'label': 'Transistor', 'icon': Icons.electrical_services},
    {'label': 'IC (Integrated Circuit)', 'icon': Icons.memory, 'short': 'ICs'},
    {'label': 'Connector', 'icon': Icons.cable},
    {'label': 'Sensor', 'icon': Icons.sensors},
    {'label': 'Switch', 'icon': Icons.toggle_on_outlined},
    {'label': 'Relay', 'icon': Icons.toggle_on_outlined},
    {
      'label': 'Crystal/Oscillator',
      'icon': Icons.radio_button_checked,
      'short': 'Crystal',
    },
    {'label': 'Fuse', 'icon': Icons.flash_on_outlined},
    {'label': 'LED', 'icon': Icons.lightbulb_outline},
    {'label': 'Cable/Wire', 'icon': Icons.cable, 'short': 'Cable'},
    {'label': 'PCB', 'icon': Icons.developer_board},
    {'label': 'Other', 'icon': Icons.category_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _query = widget.initialQuery.toLowerCase();
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
      case 'Crystal/Oscillator':
        return Icons.radio_button_checked;
      case 'Fuse':
        return Icons.flash_on_outlined;
      case 'LED':
        return Icons.lightbulb_outline;
      case 'PCB':
        return Icons.developer_board;
      default:
        return Icons.category_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: Column(
        children: [
          // Custom header — gradient-ish, better spaced
          Container(
            padding: EdgeInsets.fromLTRB(
              14,
              MediaQuery.of(context).padding.top + 12,
              14,
              16,
            ),
            decoration: BoxDecoration(
              color: primaryColor,
              // borderRadius: const BorderRadius.only(
              //   bottomLeft: Radius.circular(24),
              //   bottomRight: Radius.circular(24),
              // ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Text(
                      'Search Components',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _controller,
                          autofocus: widget.initialQuery.isEmpty,
                          decoration: InputDecoration(
                            hintText: 'Search by name, code, part no...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: primaryColor,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          onChanged: (val) =>
                              setState(() => _query = val.trim().toLowerCase()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ImageSearchScreen(),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.all(13),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              color: primaryColor,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Filter chips — scrollable, icon + label
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final label = filter['label'] as String;
                final displayLabel = filter['short'] as String? ?? label;
                final icon = filter['icon'] as IconData;
                final isSelected = _selectedFilter == label;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    avatar: Icon(
                      icon,
                      size: 15,
                      color: isSelected ? Colors.white : primaryColor,
                    ),
                    label: Text(displayLabel),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 12.5,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? primaryColor : Colors.grey.shade200,
                    ),
                    onSelected: (_) => setState(() => _selectedFilter = label),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Results
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.manage_search,
                          size: 56,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Start typing to search',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : StreamBuilder<List<ComponentModel>>(
                    stream: _componentService.getComponents(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var matches = snapshot.data!.where((c) {
                        return c.name.toLowerCase().contains(_query) ||
                            c.componentCode.toLowerCase().contains(_query) ||
                            c.partNumber.toLowerCase().contains(_query);
                      }).toList();

                      if (_selectedFilter != 'All' &&
                          _selectedFilter != 'Available' &&
                          _selectedFilter != 'Low Stock') {
                        matches = matches
                            .where((c) => c.type == _selectedFilter)
                            .toList();
                      }

                      if (matches.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 56,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No matches found',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          Text(
                            '${matches.length} RESULT${matches.length == 1 ? '' : 'S'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...matches.map(
                            (c) => _MatchCard(
                              component: c,
                              icon: _iconForType(c.type),
                              inventoryService: _inventoryService,
                              locationService: _locationService,
                              selectedFilter: _selectedFilter,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  final ComponentModel component;
  final IconData icon;
  final InventoryService inventoryService;
  final LocationService locationService;
  final String selectedFilter;

  const _MatchCard({
    required this.component,
    required this.icon,
    required this.inventoryService,
    required this.locationService,
    required this.selectedFilter,
  });

  static const Color primaryColor = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<InventoryModel>>(
      stream: inventoryService.getInventoryForComponent(component.id),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        final totalQty = records.fold<int>(0, (sum, r) => sum + r.quantity);
        final isOut = totalQty == 0;
        final isLow = !isOut && totalQty <= component.minimumStock;

        if (selectedFilter == 'Available' && (isOut || isLow))
          return const SizedBox.shrink();
        if (selectedFilter == 'Low Stock' && !isLow)
          return const SizedBox.shrink();

        final statusColor = isOut
            ? Colors.red
            : (isLow ? Colors.orange : Colors.green);
        final statusLabel = isOut
            ? 'OUT OF STOCK'
            : (isLow ? 'LOW STOCK' : 'AVAILABLE');

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    LabStaffComponentDetailScreen(component: component),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: primaryColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              component.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${component.type} • ${component.componentCode}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (records.isNotEmpty)
                        FutureBuilder<List<LocationModel>>(
                          future: locationService.getFullPath(
                            records.first.locationId,
                          ),
                          builder: (context, pathSnap) {
                            final path = pathSnap.data ?? [];
                            final pathText = path
                                .map((l) => '${l.type} ${l.name}')
                                .join(' → ');
                            return Row(
                              children: [
                                const Icon(
                                  Icons.place_outlined,
                                  size: 13,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    pathText.isEmpty ? 'Locating...' : pathText,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '$totalQty pcs',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      else
                        Text(
                          'No location assigned',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
