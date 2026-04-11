import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_provider.dart';
import '../../services/storage_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';

class EditItemScreen extends ConsumerStatefulWidget {
  const EditItemScreen({super.key});

  @override
  ConsumerState<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends ConsumerState<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  late String _selectedCategory;
  late bool _available;
  late MenuItemModel _item;
  bool _saving = false;
  bool _initialized = false;

  late List<String> _keptUrls;
  final List<String> _removedUrls = [];
  final List<XFile> _newImages = [];

  final List<_VariationRow> _variations = [];

  final _storageService = StorageService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _item = ModalRoute.of(context)!.settings.arguments as MenuItemModel;
      _nameController.text = _item.name;
      _descController.text = _item.description;
      _selectedCategory = _item.category;
      _available = _item.available;
      _keptUrls = List<String>.from(_item.imageUrls);

      // Load existing variations
      for (final entry in _item.prices.entries) {
        _variations.add(_VariationRow(
          name: entry.key,
          price: entry.value.toStringAsFixed(0),
          detail: _item.variationDetails[entry.key] ?? '',
        ));
      }
      if (_variations.isEmpty) {
        _variations.add(_VariationRow());
      }

      _initialized = true;
    }
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
                  setState(() => _newImages.addAll(files));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _storageService.takePhoto();
                if (file != null) setState(() => _newImages.add(file));
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
      for (final url in _removedUrls) {
        await _storageService.deleteImage(url);
      }

      List<String> newUrls = [];
      if (_newImages.isNotEmpty) {
        newUrls = await _storageService.uploadMultipleMenuItemImages(
          _nameController.text.trim(),
          _newImages,
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

      await ref.read(firestoreServiceProvider).updateMenuItem(_item.id, {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'description': _descController.text.trim(),
        'imageUrls': [..._keptUrls, ...newUrls],
        'available': _available,
        'prices': prices,
        'variationDetails': variationDetails,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item updated!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Item'),
        content: Text('Are you sure you want to delete "${_item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      for (final url in _item.imageUrls) {
        await _storageService.deleteImage(url);
      }
      await ref.read(firestoreServiceProvider).deleteMenuItem(_item.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item deleted'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Item'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: AppColors.accent),
            onPressed: _deleteItem,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _EditImageStrip(
                keptUrls: _keptUrls,
                newImages: _newImages,
                onRemoveUrl: (i) => setState(() {
                  _removedUrls.add(_keptUrls[i]);
                  _keptUrls.removeAt(i);
                }),
                onRemoveNew: (i) => setState(() => _newImages.removeAt(i)),
                onAdd: _addImage,
              ),
              const SizedBox(height: 20),

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
                              decoration:
                                  const InputDecoration(labelText: 'Name'),
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
                      : const Text('Save Changes'),
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
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController detailController;

  _VariationRow({String name = '', String price = '', String detail = ''})
      : nameController = TextEditingController(text: name),
        priceController = TextEditingController(text: price),
        detailController = TextEditingController(text: detail);

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    detailController.dispose();
  }
}

// ── Edit image strip ───────────────────────────────────────────────────────

class _EditImageStrip extends StatelessWidget {
  final List<String> keptUrls;
  final List<XFile> newImages;
  final void Function(int) onRemoveUrl;
  final void Function(int) onRemoveNew;
  final VoidCallback onAdd;

  const _EditImageStrip({
    required this.keptUrls,
    required this.newImages,
    required this.onRemoveUrl,
    required this.onRemoveNew,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = keptUrls.length + newImages.length;

    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          ...keptUrls.asMap().entries.map((entry) {
            final i = entry.key;
            final url = entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, err) => Container(
                        width: 110,
                        height: 110,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.local_pizza,
                            color: AppColors.primary),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => onRemoveUrl(i),
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
          ...newImages.asMap().entries.map((entry) {
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
                      onTap: () => onRemoveNew(i),
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
                  Positioned(
                    bottom: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('New',
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
                    totalCount == 0 ? 'Add photo' : 'Add more',
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
