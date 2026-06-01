import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/credit_provider.dart';

class CreditSimulatorScreen extends StatefulWidget {
  const CreditSimulatorScreen({super.key});

  @override
  State<CreditSimulatorScreen> createState() => _CreditSimulatorScreenState();
}

class _CreditSimulatorScreenState extends State<CreditSimulatorScreen> {
  final _amountCtrl = TextEditingController(text: '500000');
  double _duration = 12;
  double _rate = 12;
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  static final _fmt = NumberFormat('#,###', 'fr_FR');

  Future<void> _simulate() async {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0;
    if (amount <= 0) return;
    setState(() { _isLoading = true; });
    try {
      final result = await context.read<CreditProvider>().simulate(
        amount: amount,
        durationMonths: _duration.toInt(),
        rate: _rate,
      );
      setState(() { _result = result; });
    } catch (e) {
      // Calcul local en fallback
      final monthlyRate = _rate / 100 / 12;
      final n = _duration.toInt();
      final monthly = amount * monthlyRate * pow(1 + monthlyRate, n) / (pow(1 + monthlyRate, n) - 1);
      setState(() {
        _result = {
          'monthlyPayment': monthly,
          'totalAmount': monthly * n,
          'totalInterest': (monthly * n) - amount,
        };
      });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  double pow(double base, int exp) {
    double result = 1;
    for (int i = 0; i < exp; i++) result *= base;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Simulateur de credit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Montant du pret (FCFA)', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(suffixText: 'FCFA'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text('Duree : ${_duration.toInt()} mois', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: _duration,
                    min: 3,
                    max: 60,
                    divisions: 19,
                    activeColor: AppColors.accent,
                    label: '${_duration.toInt()} mois',
                    onChanged: (v) => setState(() { _duration = v; }),
                  ),
                  const SizedBox(height: 12),
                  Text('Taux annuel : ${_rate.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Slider(
                    value: _rate,
                    min: 5,
                    max: 30,
                    divisions: 50,
                    activeColor: AppColors.primary,
                    label: '${_rate.toStringAsFixed(1)}%',
                    onChanged: (v) => setState(() { _rate = v; }),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _simulate,
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('Calculer'),
            ),
          ),

          if (_result != null) ...[
            const SizedBox(height: 24),
            Card(
              color: AppColors.primary,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Mensualite estimee', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      '${_fmt.format((_result!['monthlyPayment'] as num).round())} FCFA',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    _SimRow('Montant total rembourse', '${_fmt.format((_result!['totalAmount'] as num).round())} F'),
                    _SimRow('Total interets', '${_fmt.format((_result!['totalInterest'] as num).round())} F'),
                    _SimRow('Duree', '${_duration.toInt()} mois'),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SimRow extends StatelessWidget {
  final String label;
  final String value;
  const _SimRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
