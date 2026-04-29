import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../controllers/auth_controller.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../services/email_service.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class _DeviceItem {
  final String id;
  final String name;
  final double functionPrice;
  final double safetyPrice;

  int qty;
  bool functionCheck;
  bool safetyCheck;

  _DeviceItem({
    required this.id,
    required this.name,
    required this.functionPrice,
    required this.safetyPrice,
  })  : qty = 0,
        functionCheck = false,
        safetyCheck = false;

  double get subtotal {
    double unit = 0;
    if (functionCheck) unit += functionPrice;
    if (safetyCheck) unit += safetyPrice;
    return unit * qty;
  }

  factory _DeviceItem.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return _DeviceItem(
      id: doc.id,
      name: d['device_name'] ?? '',
      functionPrice: (d['function_price'] ?? 0).toDouble(),
      safetyPrice: (d['safety_price'] ?? 0).toDouble(),
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class PriceOfferScreen extends StatefulWidget {
  const PriceOfferScreen({super.key});

  @override
  State<PriceOfferScreen> createState() => _PriceOfferScreenState();
}

class _PriceOfferScreenState extends State<PriceOfferScreen> {
  final _clientNameCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();

  List<_DeviceItem> _devices = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  @override
  void dispose() {
    _clientNameCtrl.dispose();
    _clientEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('devices').get();
      setState(() {
        _devices = snap.docs.map(_DeviceItem.fromDoc).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  double get _total => _devices.fold(0.0, (s, d) => s + d.subtotal);

  void _reset() {
    setState(() {
      for (final d in _devices) {
        d.qty = 0;
        d.functionCheck = false;
        d.safetyCheck = false;
      }
      _clientNameCtrl.clear();
      _clientEmailCtrl.clear();
    });
  }

  Future<void> _save() async {
    final active = _devices.where((d) => d.qty > 0).toList();
    if (active.isEmpty) {
      Get.snackbar(
        'Nothing selected',
        'Add at least one device with quantity > 0.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
      return;
    }

    final email = _clientEmailCtrl.text.trim();
    final name = _clientNameCtrl.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      Get.snackbar(
        'Missing email',
        'Enter a valid client email to send the offer.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warning,
        colorText: Colors.white,
      );
      return;
    }

    setState(() => _sending = true);

    final auth = Get.find<AuthController>();
    final engineerName = auth.appUser.value?.fullName ?? 'Engineer';

    final items = active
        .map((d) => {
              'name': d.name,
              'qty': d.qty,
              'functionCheck': d.functionCheck,
              'safetyCheck': d.safetyCheck,
              'functionPrice': d.functionPrice,
              'safetyPrice': d.safetyPrice,
              'subtotal': d.subtotal,
            })
        .toList();

    final ok = await EmailService.sendPriceOfferEmail(
      toEmail: email,
      clientName: name.isNotEmpty ? name : email,
      engineerName: engineerName,
      total: _total,
      items: items,
    );

    setState(() => _sending = false);

    if (ok) {
      Get.snackbar(
        'Offer Sent',
        'Price offer emailed to $email',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      _reset();
    } else {
      Get.snackbar(
        'Send Failed',
        'Could not send the email. Check your connection or Cloud Function.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price Offer',
              style: TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Build a maintenance quote',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Reload devices',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
            onPressed: () {
              setState(() => _loading = true);
              _loadDevices();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accent))
          : _error != null
              ? _ErrorView(
                  error: _error!,
                  onRetry: () {
                    setState(() => _loading = true);
                    _loadDevices();
                  },
                )
              : _devices.isEmpty
                  ? const _EmptyDevices()
                  : Column(
                      children: [
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(16),
                            children: [
                              _ClientCard(
                                nameCtrl: _clientNameCtrl,
                                emailCtrl: _clientEmailCtrl,
                              ),
                              const SizedBox(height: 16),
                              const _SectionLabel('Devices'),
                              const SizedBox(height: 10),
                              ..._devices.map(
                                (d) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _DeviceCard(
                                    item: d,
                                    onChanged: () => setState(() {}),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                        _TotalBar(
                          total: _total,
                          sending: _sending,
                          onReset: _reset,
                          onSave: _save,
                        ),
                      ],
                    ),
    );
  }
}

// ── Client Card ───────────────────────────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  const _ClientCard({required this.nameCtrl, required this.emailCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Client Info',
            style: TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Client Name',
            hint: 'Hospital / Clinic name',
            controller: nameCtrl,
          ),
          const SizedBox(height: 10),
          CustomTextField(
            label: 'Client Email',
            hint: 'client@hospital.com',
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
        ],
      ),
    );
  }
}

// ── Device Card ───────────────────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  final _DeviceItem item;
  final VoidCallback onChanged;
  const _DeviceCard({required this.item, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.subtotal > 0
              ? AppColors.accent.withValues(alpha: 0.4)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medical_services_outlined,
                    color: AppColors.accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(
                    fontFamily: 'Syne',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (item.subtotal > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${item.subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _PriceChip(
                label: 'Function',
                price: item.functionPrice,
                color: AppColors.accent,
              ),
              const SizedBox(width: 8),
              _PriceChip(
                label: 'Safety',
                price: item.safetyPrice,
                color: AppColors.success,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Text(
                'QTY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 10),
              _QtyField(
                value: item.qty,
                onChanged: (v) {
                  item.qty = v;
                  onChanged();
                },
              ),
              const Spacer(),
              _CheckChip(
                label: 'Function',
                value: item.functionCheck,
                onChanged: (v) {
                  item.functionCheck = v;
                  onChanged();
                },
              ),
              const SizedBox(width: 8),
              _CheckChip(
                label: 'Safety',
                value: item.safetyCheck,
                onChanged: (v) {
                  item.safetyCheck = v;
                  onChanged();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final double price;
  final Color color;
  const _PriceChip(
      {required this.label, required this.price, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$label: \$${price.toStringAsFixed(0)}',
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

// ── Qty Field ─────────────────────────────────────────────────────────────────

class _QtyField extends StatefulWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _QtyField({required this.value, required this.onChanged});

  @override
  State<_QtyField> createState() => _QtyFieldState();
}

class _QtyFieldState extends State<_QtyField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.value == 0 ? '' : widget.value.toString());
  }

  @override
  void didUpdateWidget(_QtyField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      final newText = widget.value == 0 ? '' : widget.value.toString();
      if (_ctrl.text != newText) _ctrl.text = newText;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 36,
      child: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontFamily: 'Syne',
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: const TextStyle(color: AppColors.textHint),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          filled: true,
          fillColor: AppColors.surfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
          ),
        ),
        onChanged: (v) => widget.onChanged(int.tryParse(v) ?? 0),
      ),
    );
  }
}

// ── Check Chip ────────────────────────────────────────────────────────────────

class _CheckChip extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CheckChip(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: value ? AppColors.accent : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: value ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.check_circle_rounded : Icons.circle_outlined,
              size: 14,
              color: value ? Colors.white : AppColors.textHint,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: value ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Total Bar ─────────────────────────────────────────────────────────────────

class _TotalBar extends StatelessWidget {
  final double total;
  final bool sending;
  final VoidCallback onReset;
  final VoidCallback onSave;

  const _TotalBar({
    required this.total,
    required this.sending,
    required this.onReset,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text(
                'Total Value',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '\$${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'Syne',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: sending ? null : onReset,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reset',
                      style: TextStyle(color: AppColors.textPrimary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: sending ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, size: 16),
                            SizedBox(width: 8),
                            Text('Send Offer'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Syne',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text(
              'Failed to load devices',
              style: TextStyle(
                fontFamily: 'Syne',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.price_change_outlined,
                size: 44, color: AppColors.accent),
          ),
          const SizedBox(height: 16),
          const Text(
            'No devices configured',
            style: TextStyle(
              fontFamily: 'Syne',
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add devices in Price Adjustments first.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
