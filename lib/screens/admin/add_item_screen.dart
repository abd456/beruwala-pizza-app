import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';

class AddItemScreen extends ConsumerStatefulWidget {
  const AddItemScreen({super.key});

  @override
  ConsumerState<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends ConsumerState<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  String _selectedCategory = AppConstants.menuCategories.first;
  bool _available = true;
  final List<XFile> _pickedImages = [];
  bool _saving = false;

  // Each variation: {name controller, price controller}
  final List<_VariationRow> _variations = [];

  final _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    // Start with one empty variation
    _variations.add(_VariationRow());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final v in _variations) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _addImage() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              subtitle: const Text('Select multiple photos'),
              onTap: () async {
                Navigator.pop(ctx);
                final files = await _storageService.pickMultipleImages();
                if (files.isNotEmpty) {
                  setState(() => _pickedImages.addAll(files));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _storageService.takePhoto();
                if (file != null) setState(() => _pickedImages.add(file));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      List<String> imageUrls = [];
      if (_pickedImages.isNotEmpty) {
        imageUrls = await _storageService.uploadMultipleMenuItemImages(
          _nameController.text.trim(),
          _pickedImages,
        );
      }

      final prices = <String, double>{};
      final variationDetails = <String, String>{};
      for (final v in _variations) {
        final name = v.nameController.text.trim();
        prices[name] = double.parse(v.priceController.text.trim());
        final detail = v.detailController.text.trim();
        if (detail.isNotEmpty) variationDetails[name] = detail;
      }

      final item = MenuItemModel(
        id: '',
        name: _nameController.text.trim(),
        category: _selectedCategory,
        description: _descController.text.trim(),
        imageUrls: imageUrls,
        available: _available,
        prices: prices,
        variationDetails: variationDetails,
        createdAt: DateTime.now(),
      );

      await ref.read(firestoreServiceProvider).addMenuItem(item);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item added successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image strip
              _ImageStrip(
                images: _pickedImages,
                onAdd: _addImage,
                onRemove: (i) => setState(() => _pickedImages.removeAt(i)),
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Item Name',
                  prefixIcon: Icon(Icons.local_pizza_outlined),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter item name' : null,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: AppConstants.menuCategories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),

              // Variations
              Row(
                children: [
                  Text('Variations (LKR)',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () =>
                        setState(() => _variations.add(_VariationRow())),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._variations.asMap().entries.map((entry) {
                final i = entry.key;
                final v = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              controller: v.nameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                hintText: i == 0 ? 'e.g. Small' : 'e.g. Large',
                              ),
                              validator: (val) =>
                                  val == null || val.trim().isEmpty
                                      ? 'Required'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 4,
                            child: TextFormField(
                              controller: v.priceController,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Price'),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) {
                                  return 'Required';
                                }
                                if (double.tryParse(val.trim()) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (_variations.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close,
                                  size: 20, color: Colors.red),
                              onPressed: () => setState(() {
                                _variations[i].dispose();
                                _variations.removeAt(i);
                              }),
                            )
                          else
                            const SizedBox(width: 44),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: v.detailController,
                        decoration: const InputDecoration(
                          labelText: 'Detail (optional)',
                          hintText: 'e.g. 12 inch, 500ml',
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 12),

              // Available toggle
              SwitchListTile(
                title: const Text('Available'),
                subtitle: Text(
                  _available ? 'Visible to customers' : 'Hidden from menu',
                ),
                value: _available,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _available = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveItem,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : const Text('Add Item'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _VariationRow {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController detailController = TextEditingController();

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    detailController.dispose();
  }
}

// ── Image strip ────────────────────────────────────────────────────────────

class _ImageStrip extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _ImageStrip({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...images.asMap().entries.map((entry) {
            final i = entry.key;
            final file = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(file.path),
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemove(i),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  if (i == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Cover',
                            style:
                                TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ],
              ),
            );
          }),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.textGrey.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 32,
                      color: AppColors.textGrey.withValues(alpha: 0.5)),
                  const SizedBox(height: 4),
                  Text(
                    images.isEmpty ? 'Add photo' : 'Add more',
                    style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textGrey.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
