// lib/screens/admin/edit_component_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internshiptask/services/storage_service.dart';
import '../../constants/component_constants.dart';
import '../../models/component_model.dart';
import '../../services/component_service.dart';

class EditComponentScreen extends StatefulWidget {
  final ComponentModel component;
  const EditComponentScreen({super.key, required this.component});

  @override
  State<EditComponentScreen> createState() => _EditComponentScreenState();
}

class _EditComponentScreenState extends State<EditComponentScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _manufacturerController;
  late TextEditingController _partNumberController;
  late TextEditingController _descriptionController;
  late TextEditingController _minStockController;

  late String _selectedType;
  bool _isLoading = false;
  String? _errorMessage;

  final _componentService = ComponentService();
  static const Color primaryColor = Color(0xFF6C63FF);
  late List<String> _existingImageUrls;
  final List<XFile> _newImages = [];
  final _storageService = StorageService();
  bool _isUploadingImages = false;

  @override
  void initState() {
    super.initState();
    final c = widget.component;
    _existingImageUrls = List.from(widget.component.imageUrls);
    _nameController = TextEditingController(text: c.name);
    _manufacturerController = TextEditingController(text: c.manufacturer);
    _partNumberController = TextEditingController(text: c.partNumber);
    _descriptionController = TextEditingController(text: c.description);
    _minStockController = TextEditingController(text: '${c.minimumStock}');
    _selectedType = componentTypes.contains(c.type)
        ? c.type
        : componentTypes.first;
  }

  Future<void> _pickNewImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 70);
    if (images.isNotEmpty) {
      setState(() => _newImages.addAll(images));
    }
  }

  void _removeExistingImage(int index) {
    setState(() => _existingImageUrls.removeAt(index));
  }

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Naye images upload karo
      List<String> uploadedUrls = [];
      if (_newImages.isNotEmpty) {
        setState(() => _isUploadingImages = true);
        uploadedUrls = await _storageService.uploadImages(
          files: _newImages,
          componentCode: widget.component.componentCode,
        );
        setState(() => _isUploadingImages = false);
      }

      // Jo images remove ki gayi hain unhe Supabase se bhi delete karo
      final removedUrls = widget.component.imageUrls
          .where((url) => !_existingImageUrls.contains(url))
          .toList();
      for (var url in removedUrls) {
        await _storageService.deleteImage(url);
      }

      final finalImageUrls = [..._existingImageUrls, ...uploadedUrls];

      await _componentService.updateComponent(widget.component.id, {
        'name': _nameController.text.trim(),
        'type': _selectedType,
        'manufacturer': _manufacturerController.text.trim(),
        'partNumber': _partNumberController.text.trim(),
        'description': _descriptionController.text.trim(),
        'minimumStock': int.tryParse(_minStockController.text.trim()) ?? 0,
        'imageUrls': finalImageUrls,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Component updated successfully!')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      appBar: AppBar(
        title: const Text('Edit Component'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Locked fields — read-only display
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Component Code: ${widget.component.componentCode}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'ABC Class: ${widget.component.abcdClass} (Rack ${widget.component.abcdClass})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Code and Class cannot be changed after creation. '
                    'If needed, create a new component instead.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

            const Text(
              'Component Name *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
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
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: componentTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
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
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),

            const Text(
              'Minimum Stock Level *',
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
              'Detailed Description',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 20),
            const SizedBox(height: 20),
            const Text(
              'Component Images',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),

            // Existing images
            if (_existingImageUrls.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _existingImageUrls.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _existingImageUrls[index],
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _removeExistingImage(index),
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

            // Newly picked images
            if (_newImages.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 90,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _newImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _newImages[index].path,
                              width: 90,
                              height: 90,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _removeNewImage(index),
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

            const SizedBox(height: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: const Text('Add More Images'),
              onPressed: _pickNewImages,
            ),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),

            _isLoading
                ? const Center(child: CircularProgressIndicator())
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
                        'Save Changes',
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
