import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/shop_settings_model.dart';
import '../../providers/menu_provider.dart';
import '../../utils/app_colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local mutable state — seeded from Firestore on first build
  bool _initialised = false;
  bool _isManuallyClosedNow = false;
  int _estimatedWaitMinutes = 30;

  // A mutable copy of weeklyHours keyed by day name
  late Map<String, _DayState> _dayStates;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with defaults; will be overwritten in build() on first data
    _seedDefaults(ShopSettingsModel.defaults());
  }

  void _seedDefaults(ShopSettingsModel model) {
    _isManuallyClosedNow = model.isManuallyClosedNow;
    _estimatedWaitMinutes = model.estimatedWaitMinutes;
    _dayStates = {
      for (final day in ShopSettingsModel.daysOfWeek)
        day: _DayState.fromDayHours(model.weeklyHours[day]!),
    };
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final data = ShopSettingsModel(
        isManuallyClosedNow: _isManuallyClosedNow,
        estimatedWaitMinutes: _estimatedWaitMinutes,
        weeklyHours: {
          for (final day in ShopSettingsModel.daysOfWeek)
            day: _dayStates[day]!.toDayHours(),
        },
      ).toMap();

      await ref.read(firestoreServiceProvider).updateShopSettings(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickTime(String day, bool isOpen) async {
    final state = _dayStates[day]!;
    final initialString = isOpen ? state.open : state.close;
    final parts = initialString.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 9,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isOpen) {
          _dayStates[day] = state.copyWith(open: formatted);
        } else {
          _dayStates[day] = state.copyWith(close: formatted);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(shopSettingsProvider);

    // Seed local state from Firestore exactly once on first successful load
    settingsAsync.whenData((settings) {
      if (!_initialised && settings != null) {
        _initialised = true;
        // Use addPostFrameCallback to avoid setState during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _seedDefaults(settings));
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Shop Settings'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Closed Now toggle ──────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Closed Now',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    _isManuallyClosedNow
                        ? 'Shop is forced closed — customers cannot order'
                        : 'Shop follows the weekly schedule below',
                    style: const TextStyle(fontSize: 13),
                  ),
                  value: _isManuallyClosedNow,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isManuallyClosedNow = v),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Estimated wait ─────────────────────────────────────────────
            Text('Estimated Wait Time',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Minutes', style: TextStyle(fontSize: 16)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _estimatedWaitMinutes > 5
                              ? () => setState(
                                  () => _estimatedWaitMinutes -= 5)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppColors.primary,
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '$_estimatedWaitMinutes',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _estimatedWaitMinutes += 5),
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Weekly schedule ────────────────────────────────────────────
            Text('Weekly Hours',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),

            ...ShopSettingsModel.daysOfWeek.map((day) {
              final state = _dayStates[day]!;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day name row + closed-all-day toggle
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${day[0].toUpperCase()}${day.substring(1)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const Text(
                            'Closed all day',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textGrey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Switch(
                            value: state.isClosedAllDay,
                            activeThumbColor: AppColors.primary,
                            onChanged: (v) => setState(
                              () => _dayStates[day] =
                                  state.copyWith(isClosedAllDay: v),
                            ),
                          ),
                        ],
                      ),

                      // Time pickers — only shown when not closed all day
                      if (!state.isClosedAllDay) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: _TimeButton(
                                label: 'Open',
                                time: state.open,
                                onTap: () => _pickTime(day, true),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TimeButton(
                                label: 'Close',
                                time: state.close,
                                onTap: () => _pickTime(day, false),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // ── Save button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : const Text('Save Settings'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Private helpers ──────────────────────────────────────────────────────────

/// Mutable local copy of a single day's state, used only inside this screen.
class _DayState {
  final bool isClosedAllDay;
  final String open;
  final String close;

  const _DayState({
    required this.isClosedAllDay,
    required this.open,
    required this.close,
  });

  factory _DayState.fromDayHours(DayHours h) => _DayState(
        isClosedAllDay: h.isClosedAllDay,
        open: h.open,
        close: h.close,
      );

  DayHours toDayHours() => DayHours(
        isClosedAllDay: isClosedAllDay,
        open: open,
        close: close,
      );

  _DayState copyWith({bool? isClosedAllDay, String? open, String? close}) =>
      _DayState(
        isClosedAllDay: isClosedAllDay ?? this.isClosedAllDay,
        open: open ?? this.open,
        close: close ?? this.close,
      );
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.access_time, size: 16),
      label: Text('$label  $time'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}
