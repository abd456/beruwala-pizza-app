import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/menu_provider.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_constants.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  bool _saving = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _prefill(UserModel user) {
    if (_prefilled) return;
    _prefilled = true;
    _nameController.text = user.name;
  }

  Future<void> _saveProfile(UserModel user) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(firestoreServiceProvider).updateUserProfile(
            user.uid,
            name: name,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _addAddress(UserModel user) async {
    final result = await _showAddressDialog(context);
    if (result == null) return;

    final existing = List<SavedAddress>.from(user.addresses);

    // Auto-label: Home → Work → Address n
    final labels = existing.map((a) => a.label).toSet();
    String label = 'Home';
    if (labels.contains('Home')) label = 'Work';
    if (labels.contains('Work')) label = 'Address ${existing.length + 1}';

    final newAddress = SavedAddress(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      label: result['label'] ?? label,
      address: result['address']!,
      contactName: result['contactName'] ?? '',
      contactPhone: result['contactPhone'] ?? '',
      isDefault: existing.isEmpty,
    );

    existing.add(newAddress);
    await ref
        .read(firestoreServiceProvider)
        .saveUserAddresses(user.uid, existing);
  }

  Future<void> _deleteAddress(UserModel user, SavedAddress addr) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Remove "${addr.label}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    var updated = user.addresses.where((a) => a.id != addr.id).toList();
    // If we deleted the default and others remain, make first one default
    if (addr.isDefault && updated.isNotEmpty) {
      updated[0] = updated[0].copyWith(isDefault: true);
    }
    await ref
        .read(firestoreServiceProvider)
        .saveUserAddresses(user.uid, updated);
  }

  Future<void> _setDefault(UserModel user, SavedAddress addr) async {
    final updated = user.addresses
        .map((a) => a.copyWith(isDefault: a.id == addr.id))
        .toList();
    await ref
        .read(firestoreServiceProvider)
        .saveUserAddresses(user.uid, updated);
  }

  Future<void> _editAddress(UserModel user, SavedAddress addr) async {
    final result = await _showAddressDialog(
      context,
      initialLabel: addr.label,
      initialAddress: addr.address,
      initialContactName: addr.contactName,
      initialContactPhone: addr.contactPhone,
    );
    if (result == null) return;

    final updated = user.addresses
        .map((a) => a.id == addr.id
            ? a.copyWith(
                label: result['label'],
                address: result['address'],
                contactName: result['contactName'],
                contactPhone: result['contactPhone'],
              )
            : a)
        .toList();
    await ref
        .read(firestoreServiceProvider)
        .saveUserAddresses(user.uid, updated);
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userModelProvider);
    final user = userAsync.valueOrNull;

    if (user != null) _prefill(user);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (user != null)
            TextButton(
              onPressed: _saving ? null : () => _saveProfile(user),
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: userAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Not logged in'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile fields ──────────────────────────────────
                Text('Personal Info',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    prefixIcon: Icon(Icons.person_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                // Account phone is the login credential — read-only
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Account Number (login)',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.4),
                  ),
                  child: Text(
                    user.phone,
                    style: TextStyle(color: AppColors.textGrey),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    'This is your login number and cannot be changed.',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey),
                  ),
                ),
                const SizedBox(height: 32),

                // ── Saved addresses ──────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Saved Addresses',
                        style: Theme.of(context).textTheme.titleLarge),
                    TextButton.icon(
                      onPressed: () => _addAddress(user),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (user.addresses.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No saved addresses yet.\nAdd one to speed up checkout.',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  )
                else
                  ...user.addresses.map((addr) => _AddressTile(
                        address: addr,
                        onSetDefault: () => _setDefault(user, addr),
                        onEdit: () => _editAddress(user, addr),
                        onDelete: () => _deleteAddress(user, addr),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Address dialog ─────────────────────────────────────────────────��───────

Future<Map<String, String>?> _showAddressDialog(
  BuildContext context, {
  String? initialLabel,
  String? initialAddress,
  String? initialContactName,
  String? initialContactPhone,
}) async {
  final labelController = TextEditingController(text: initialLabel ?? '');
  final addressController = TextEditingController(text: initialAddress ?? '');
  final contactNameController =
      TextEditingController(text: initialContactName ?? '');
  final contactPhoneController =
      TextEditingController(text: initialContactPhone ?? '');

  return showDialog<Map<String, String>>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(initialAddress == null ? 'Add Address' : 'Edit Address'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(
                labelText: 'Label (e.g. Home, Mum\'s Place)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contactNameController,
              decoration: const InputDecoration(
                labelText: 'Contact Name',
                hintText: 'Who receives the order?',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Contact Phone',
                hintText: 'Their number',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Full Address'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final addr = addressController.text.trim();
            if (addr.isEmpty) return;
            Navigator.pop(context, {
              'label': labelController.text.trim().isEmpty
                  ? 'Address'
                  : labelController.text.trim(),
              'address': addr,
              'contactName': contactNameController.text.trim(),
              'contactPhone': contactPhoneController.text.trim(),
            });
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}

// ── Address tile widget ────────────────────────────────────────────────────

class _AddressTile extends StatelessWidget {
  final SavedAddress address;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AddressTile({
    required this.address,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.location_on_outlined,
              color: address.isDefault ? AppColors.primary : AppColors.textGrey,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (address.contactName.isNotEmpty)
                    Text(
                      '${address.contactName}${address.contactPhone.isNotEmpty ? ' · ${address.contactPhone}' : ''}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  const SizedBox(height: 2),
                  Text(address.address,
                      style: TextStyle(color: AppColors.textGrey)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'default') onSetDefault();
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                if (!address.isDefault)
                  const PopupMenuItem(
                      value: 'default',
                      child: Text('Set as default')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
