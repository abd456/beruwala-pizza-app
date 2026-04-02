import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final _smallPriceController = TextEditingController();
  final _mediumPriceController = TextEditingController();
  final _largePriceController = TextEditingController();

  late String _selectedCategory;
  late bool _available;
  late MenuItemModel _item;
  XFile? _pickedImage;
  bool _saving = false;
  bool _initialized = false;

  final _storageService = StorageService();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _item = ModalRoute.of(context)!.settings.arguments as MenuItemModel;
      _nameController.text = _item.name;
      _descController.text = _item.description;
      _smallPriceController.text =
          _item.getPrice(AppConstants.sizeSmall).toStringAsFixed(0);
      _mediumPriceController.text =
          _item.getPrice(AppConstants.sizeMedium).toStringAsFixed(0);
      _largePriceController.text =
          _item.getPrice(AppConstants.sizeLarge).toStringAsFixed(0);
      _selectedCategory = _item.category;
      _available = _item.available;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _smallPriceController.dispose();
    _mediumPriceController.dispose();
    _largePriceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _storageService.pickImage();
                if (file != null) setState(() => _pickedImage = file);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _storageService.takePhoto();
                if (file != null) setState(() => _pickedImage = file);
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
      String imageUrl = _item.imageUrl;

      if (_pickedImage != null) {
        // Delete old image if exists
        if (_item.imageUrl.isNotEmpty) {
          await _storageService.deleteImage(_item.imageUrl);
        }
        imageUrl = await _storageService.uploadMenuItemImage(
          _nameController.text.trim(),
          _pickedImage!,
        );
      }

      await ref.read(firestoreServiceProvider).updateMenuItem(_item.id, {
        'name': _nameController.text.trim(),
        'category': _selectedCategory,
        'description': _descController.text.trim(),
        'imageUrl': imageUrl,
        'available': _available,
        'prices': {
          AppConstants.sizeSmall:
              double.parse(_smallPriceController.text.trim()),
          AppConstants.sizeMedium:
              double.parse(_mediumPriceController.text.trim()),
          AppConstants.sizeLarge:
              double.parse(_largePriceController.text.trim()),
        },
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
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      if (_item.imageUrl.isNotEmpty) {
        await _storageService.deleteImage(_item.imageUrl);
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
      backgroundColor: AppColors.background,
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
              // Image
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.textGrey.withValues(alpha: 0.3),
                      ),
                    ),
                    child: _pickedImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(
                              File(_pickedImage!.path),
                              fit: BoxFit.cover,
                            ),
                          )
                        : _item.imageUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: CachedNetworkImage(
                                  imageUrl: _item.imageUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) => const Icon(
                                    Icons.local_pizza,
                                    size: 48,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: AppColors.textGrey
                                          .withValues(alpha: 0.5)),
                                  const SizedBox(height: 8),
                                  Text('Tap to change photo',
                                      style: TextStyle(
                                          color: AppColors.textGrey
                                              .withValues(alpha: 0.7))),
                                ],
                              ),
                  ),
                ),
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

              // Prices
              Text('Pricing (LKR)',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _smallPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Small'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _mediumPriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Medium'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _largePriceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Large'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
