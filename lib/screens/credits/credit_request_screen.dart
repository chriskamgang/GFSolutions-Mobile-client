import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/credit_provider.dart';
import '../../widgets/loading_overlay.dart';

class CreditRequestScreen extends StatefulWidget {
  const CreditRequestScreen({super.key});

  @override
  State<CreditRequestScreen> createState() => _CreditRequestScreenState();
}

class _CreditRequestScreenState extends State<CreditRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  final _guarantorNameCtrl = TextEditingController();
  final _guarantorPhoneCtrl = TextEditingController();
  int _duration = 12;
  bool _isLoading = false;
  final List<XFile> _documents = [];

  Future<void> _pickDocument() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      setState(() { _documents.add(file); });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountCtrl.text.replaceAll(' ', '')) ?? 0;
    if (amount <= 0) return;

    setState(() { _isLoading = true; });
    try {
      await context.read<CreditProvider>().submitRequest(
        amount: amount,
        durationMonths: _duration,
        purpose: _purposeCtrl.text,
        guarantorName: _guarantorNameCtrl.text.isNotEmpty ? _guarantorNameCtrl.text : null,
        guarantorPhone: _guarantorPhoneCtrl.text.isNotEmpty ? _guarantorPhoneCtrl.text : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Demande de credit soumise !'), backgroundColor: AppColors.success),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      message: 'Envoi de la demande...',
      child: Scaffold(
        appBar: AppBar(title: const Text('Demande de credit')),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(child: Text('Remplissez le formulaire ci-dessous. Votre demande sera examinee par un agent.', style: TextStyle(fontSize: 12))),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Montant souhaite (FCFA)', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'Ex: 500000', suffixText: 'FCFA'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      Text('Duree souhaitee : $_duration mois', style: const TextStyle(fontWeight: FontWeight.w600)),
                      Slider(
                        value: _duration.toDouble(),
                        min: 3,
                        max: 60,
                        divisions: 19,
                        activeColor: AppColors.accent,
                        label: '$_duration mois',
                        onChanged: (v) => setState(() { _duration = v.toInt(); }),
                      ),
                      const SizedBox(height: 16),
                      const Text('Objet du pret', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _purposeCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(hintText: 'Ex: Fonds de commerce, achat vehicule...'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text('Garant (optionnel)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _guarantorNameCtrl,
                        decoration: const InputDecoration(labelText: 'Nom du garant'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _guarantorPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(labelText: 'Telephone du garant'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Documents
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Justificatifs', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      const Text('Photos de pieces, factures, etc.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._documents.asMap().entries.map((entry) => Chip(
                            label: Text('Doc ${entry.key + 1}', style: const TextStyle(fontSize: 12)),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => setState(() { _documents.removeAt(entry.key); }),
                          )),
                          ActionChip(
                            avatar: const Icon(Icons.add_photo_alternate, size: 18),
                            label: const Text('Ajouter'),
                            onPressed: _pickDocument,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Soumettre la demande'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
