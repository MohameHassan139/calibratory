import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/price/device_card.dart';

class PriceOfferScreen extends StatefulWidget {
  const PriceOfferScreen({super.key});

  @override
  State<PriceOfferScreen> createState() => _PriceOfferScreenState();
}

class _PriceOfferScreenState extends State<PriceOfferScreen> {
  final Map<String, double> prices = {};
  final Map<String, int> quantities = {};
  final Map<String, bool> electricCheck = {};
  final Map<String, bool> functionCheck = {};
  final _clientNameCtrl = TextEditingController();
  final _clientEmailCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (var device in MonitorConstants.deviceTypes) {
      prices[device] = 0;
      quantities[device] = 0;
      electricCheck[device] = false;
      functionCheck[device] = false;
    }
  }

  double get total => MonitorConstants.deviceTypes
      .fold(0, (sum, d) => sum + (prices[d]! * quantities[d]!));

  void _reset() {
    setState(() {
      for (var d in MonitorConstants.deviceTypes) {
        prices[d] = 0;
        quantities[d] = 0;
        electricCheck[d] = false;
        functionCheck[d] = false;
      }
    });
  }

  void _sendOffer() {
    if (_clientEmailCtrl.text.contains('@')) {
      Get.snackbar(
        'Offer Sent!',
        'Price offer has been sent to ${_clientEmailCtrl.text}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Price Offer'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Client info card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        CustomTextField(
                          label: 'Client Name',
                          hint: 'Hospital / Clinic name',
                          controller: _clientNameCtrl,
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          label: 'Client Email',
                          hint: 'client@hospital.com',
                          controller: _clientEmailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Device cards
                  ...MonitorConstants.deviceTypes.map((device) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: DeviceCard(
                          device: device,
                          price: prices[device]!,
                          qty: quantities[device]!,
                          electric: electricCheck[device]!,
                          function: functionCheck[device]!,
                          onPriceChanged: (v) =>
                              setState(() => prices[device] = v),
                          onQtyChanged: (v) =>
                              setState(() => quantities[device] = v),
                          onElectricChanged: (v) =>
                              setState(() => electricCheck[device] = v),
                          onFunctionChanged: (v) =>
                              setState(() => functionCheck[device] = v),
                        ),
                      )),
                ],
              ),
            ),
          ),
          _TotalBar(total: total, onReset: _reset, onSend: _sendOffer),
        ],
      ),
    );
  }
}

class _TotalBar extends StatelessWidget {
  final double total;
  final VoidCallback onReset;
  final VoidCallback onSend;

  const _TotalBar({
    required this.total,
    required this.onReset,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Total Value',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 16,
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
                  onPressed: onReset,
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
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save to History'),
                  onPressed: onSend,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
