// lib/screens/admin/add_component_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/component_constants.dart';
import '../../models/component_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/component_service.dart';
import '../../services/inventory_service.dart';
import '../../widgets/cascading_location_picker.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';

class AddComponentScreen extends StatefulWidget {
  const AddComponentScreen({super.key});

  @override
  State<AddComponentScreen> createState() => _AddComponentScreenState();
}

class _AddComponentScreenState extends State<AddComponentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _minStockController = TextEditingController(text: '10');
  final List<XFile> _pickedImages = [];
  final _storageService = StorageService();
  bool _isUploadingImages = false;

  String? _selectedType;
  String _selectedAbcdClass = 'A';
  int _initialQuantity = 0;
  String? _selectedBoxLocationId;

  bool _isLoading = false;
  String? _errorMessage;

  final _componentService = ComponentService();
  final _inventoryService = InventoryService();
  static const Color primaryColor = Color(0xFF6C63FF);

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (image != null) {
      setState(() => _pickedImages.add(image));
    }
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      setState(() => _pickedImages.addAll(images));
    }
  }

  void _removePickedImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_initialQuantity > 0 && _selectedBoxLocationId == null) {
      setState(
        () => _errorMessage =
            'Please select a shelf and box for the initial stock',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = context.read<AuthProvider>().userModel!;
      final code = _codeController.text.trim().toUpperCase();

      // 👇 Pehle images upload karo (agar select ki hain)
      List<String> imageUrls = [];
      if (_pickedImages.isNotEmpty) {
        setState(() => _isUploadingImages = true);
        imageUrls = await _storageService.uploadImages(
          files: _pickedImages,
          componentCode: code,
        );
        setState(() => _isUploadingImages = false);
      }

      final component = ComponentModel(
        id: code,
        name: _nameController.text.trim(),
        componentCode: code,
        type: _selectedType ?? componentTypes.first,
        manufacturer: _manufacturerController.text.trim(),
        partNumber: _partNumberController.text.trim(),
        abcdClass: _selectedAbcdClass,
        description: _descriptionController.text.trim(),
        minimumStock: int.tryParse(_minStockController.text.trim()) ?? 0,
        imageUrls: imageUrls, // 👈 naya
        createdBy: currentUser.id,
      );

      await _componentService.addComponent(component);

      if (_initialQuantity > 0 && _selectedBoxLocationId != null) {
        await _inventoryService.addStock(
          componentId: code,
          locationId: _selectedBoxLocationId!,
          quantity: _initialQuantity,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Component "$code" added successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _sectionCard({
    required String title,
    IconData? icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: primaryColor),
                const SizedBox(width: 6),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Add New Component'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Inventory  >  Add Component',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter details for a new inventory item to track in the system.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Basic Information
            _sectionCard(
              title: 'Basic Information',
              icon: Icons.info_outline,
              children: [
                const Text(
                  'Component Name *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 10k Ohm Resistor 1/4W',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                const Text(
                  'Component Code *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'e.g. RES-001 (must be unique)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                const Text(
                  'Category *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    hintText: 'Select Category',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: componentTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedType = val),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                const Text(
                  'Manufacturer',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _manufacturerController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Yageo',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'Manufacturer Part Number (MPN)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _partNumberController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. RC0402FR-0710KL',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),

                const Text(
                  'Detailed Description',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText:
                        'Enter specifications, datasheet links, or special handling instructions...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),

            // Inventory Rules
            _sectionCard(
              title: 'Inventory Rules',
              icon: Icons.rule,
              children: [
                const Text(
                  'Initial Quantity *',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        if (_initialQuantity > 0) _initialQuantity--;
                      }),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$_initialQuantity',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _initialQuantity++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                const Text(
                  'Min Stock Level',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _minStockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (int.tryParse(v) == null) return 'Enter a valid number';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                const Text(
                  'ABC Classification',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedAbcdClass,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: abcdClassDescriptions.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text('${e.key} — ${e.value}'),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() {
                    _selectedAbcdClass = val!;
                    _selectedBoxLocationId =
                        null; // reset kyunki rack change hui
                  }),
                ),
              ],
            ),

            // Storage Location
            _sectionCard(
              title: 'Storage Location',
              icon: Icons.location_on_outlined,
              children: [
                Text(
                  'Rack is automatically assigned based on ABC Classification (Class $_selectedAbcdClass → Rack $_selectedAbcdClass).',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                if (_initialQuantity == 0)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Set an Initial Quantity above to assign a storage location now, or add stock later from the component page.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  )
                else
                  CascadingLocationPicker(
                    key: ValueKey(_selectedAbcdClass),
                    rackCode: _selectedAbcdClass,
                    onBoxSelected: (boxId) =>
                        setState(() => _selectedBoxLocationId = boxId),
                  ),
              ],
            ),

            // Media & Identification
            _sectionCard(
              title: 'Media & Identification',
              icon: Icons.image_outlined,
              children: [
                const Text(
                  'Component Image',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickImages,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.photo_library_outlined,
                                color: primaryColor,
                                size: 26,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Gallery',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Choose multiple',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InkWell(
                        onTap: _captureImage,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                color: primaryColor,
                                size: 26,
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Camera',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Take a photo',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                if (_pickedImages.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 90,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _pickedImages.length,
                      itemBuilder: (context, index) {
                        final img = _pickedImages[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: kIsWeb
                                    ? Image.network(
                                        img.path,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        File(img.path),
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: GestureDetector(
                                  onTap: () => _removePickedImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.qr_code_2, color: primaryColor, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'A unique tracking code is generated from the Component Code you entered above.',
                          style: TextStyle(fontSize: 11, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 12),

            (_isLoading || _isUploadingImages)
                ? const Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text(
                          'Uploading...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                      ),
                      icon: const Icon(
                        Icons.save_outlined,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Save Component',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: _submit,
                    ),
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
