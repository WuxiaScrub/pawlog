import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/database.dart';
import '../../core/photo_storage.dart';
import '../../providers/cats_provider.dart';
import 'cat_avatar.dart';

class _PhotoChoice {
  _PhotoChoice(this.source);
  final ImageSource? source;
}

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
  bool _weightInLbs = true;
  DateTime? _dateOfBirth;
  String? _photoPath;
  bool _saving = false;

  final _photoStorage = const PhotoStorage();

  @override
  void initState() {
    super.initState();
    final cat = widget.existingCat;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _breedController = TextEditingController(text: cat?.breed ?? '');
    if (cat?.weightKg != null) {
      // Display existing weight in lbs by default.
      final lbs = cat!.weightKg! / 0.453592;
      _weightController =
          TextEditingController(text: lbs.toStringAsFixed(1));
    } else {
      _weightController = TextEditingController();
    }
    _dateOfBirth = cat?.dateOfBirth;
    _photoPath = cat?.photoPath;
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

  Future<void> _pickPhoto() async {
    final result = await showModalBottomSheet<_PhotoChoice>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext)
                  .pop(_PhotoChoice(ImageSource.camera)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext)
                  .pop(_PhotoChoice(ImageSource.gallery)),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Remove photo'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_PhotoChoice(null)),
              ),
          ],
        ),
      ),
    );

    if (result == null) return;

    if (result.source == null) {
      setState(() => _photoPath = null);
      return;
    }

    try {
      final saved = await _photoStorage.pickAndSave(source: result.source!);
      if (saved != null) setState(() => _photoPath = saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save photo: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final rawWeight = double.tryParse(_weightController.text.trim());
    final weight = rawWeight == null
        ? null
        : _weightInLbs
            ? rawWeight * 0.453592
            : rawWeight;
    final repo = ref.read(catsRepositoryProvider);

    if (widget.existingCat == null) {
      await repo.addCat(
        name: _nameController.text.trim(),
        breed: _breedController.text.trim().isEmpty
            ? null
            : _breedController.text.trim(),
        dateOfBirth: _dateOfBirth,
        weightKg: weight,
        photoPath: _photoPath,
      );
      // _Root will automatically navigate to CatCareScreeningScreen
      // once the new cat (screeningDone = false) appears in the stream.
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
          photoPath: drift.Value(_photoPath),
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
              Center(
                child: Stack(
                  children: [
                    CatAvatar(photoPath: _photoPath, radius: 48),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton.filled(
                        icon: const Icon(Icons.edit, size: 18),
                        onPressed: _pickPhoto,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText:
                            'Weight (${_weightInLbs ? 'lbs' : 'kg'})',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('lbs')),
                      ButtonSegment(value: false, label: Text('kg')),
                    ],
                    selected: {_weightInLbs},
                    onSelectionChanged: (sel) {
                      final newInLbs = sel.first;
                      if (newInLbs == _weightInLbs) return;
                      final raw = double.tryParse(
                          _weightController.text.trim());
                      setState(() {
                        _weightInLbs = newInLbs;
                        if (raw != null) {
                          final converted = newInLbs
                              ? raw / 0.453592
                              : raw * 0.453592;
                          _weightController.text =
                              converted.toStringAsFixed(1);
                        }
                      });
                    },
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ],
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
