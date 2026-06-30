import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database.dart';
import '../../providers/cats_provider.dart';

class CatProfileSetupScreen extends ConsumerStatefulWidget {
  const CatProfileSetupScreen({super.key, this.existingCat});

  final Cat? existingCat;

  @override
  ConsumerState<CatProfileSetupScreen> createState() =>
      _CatProfileSetupScreenState();
}

class _CatProfileSetupScreenState
    extends ConsumerState<CatProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _breedController;
  late final TextEditingController _weightController;
  DateTime? _dateOfBirth;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final cat = widget.existingCat;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _breedController = TextEditingController(text: cat?.breed ?? '');
    _weightController =
        TextEditingController(text: cat?.weightKg?.toString() ?? '');
    _dateOfBirth = cat?.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime.now(),
      firstDate: DateTime(1995),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final weight = double.tryParse(_weightController.text.trim());
    final repo = ref.read(catsRepositoryProvider);

    if (widget.existingCat == null) {
      await repo.addCat(
        name: _nameController.text.trim(),
        breed: _breedController.text.trim().isEmpty
            ? null
            : _breedController.text.trim(),
        dateOfBirth: _dateOfBirth,
        weightKg: weight,
      );
    } else {
      await repo.updateCat(
        widget.existingCat!.copyWith(
          name: _nameController.text.trim(),
          breed: drift.Value(
            _breedController.text.trim().isEmpty
                ? null
                : _breedController.text.trim(),
          ),
          dateOfBirth: drift.Value(_dateOfBirth),
          weightKg: drift.Value(weight),
        ),
      );
    }

    if (mounted) {
      if (widget.existingCat != null) {
        Navigator.of(context).pop();
      }
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCat != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Cat' : 'Add Your Cat')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (!isEditing)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Let\'s set up your cat\'s profile to start logging care events.',
                  ),
                ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _breedController,
                decoration: const InputDecoration(labelText: 'Breed'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  _dateOfBirth == null
                      ? 'Date of birth'
                      : 'DOB: ${_dateOfBirth!.toLocal().toString().split(' ').first}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateOfBirth,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Create Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
