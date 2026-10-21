import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading.dart' show showMessage;
import '../data/item_categories.dart';
import '../data/item_repository.dart';

class ReportItemScreen extends ConsumerStatefulWidget {
  const ReportItemScreen({super.key});
  @override
  ConsumerState<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends ConsumerState<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _picker = ImagePicker();
  String _type = 'lost';
  String _category = itemCategories.first;
  DateTime _occurredAt = DateTime.now();
  Uint8List? _photoBytes;
  String? _photoName;
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 85, maxWidth: 1800);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _photoBytes = bytes;
          _photoName = file.name;
        });
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Could not open your photos.', isError: true);
      }
    }
  }

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate: _occurredAt.isAfter(now) ? now : _occurredAt,
      firstDate: DateTime(now.year - 15),
      lastDate: now,
      helpText:
          _type == 'lost' ? 'When did you lose it?' : 'When did you find it?',
    );
    if (chosen != null) setState(() => _occurredAt = chosen);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(itemRepositoryProvider).createListing(
            title: _title.text,
            description: _description.text,
            type: _type,
            category: _category,
            location: _location.text,
            occurredAt: _occurredAt,
            photoBytes: _photoBytes,
            photoName: _photoName,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        showMessage(context,
            'Your post could not be saved. Check your connection and try again.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Create a report')),
        body: Form(
          key: _formKey,
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 5, 20, 32),
              children: [
                const Text('Help the right person spot it.',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 6),
                const Text('A few clear details make all the difference.',
                    style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 21),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'lost',
                        label: Text('I lost something'),
                        icon: Icon(Icons.search_rounded)),
                    ButtonSegment(
                        value: 'found',
                        label: Text('I found something'),
                        icon: Icon(Icons.volunteer_activism_outlined)),
                  ],
                  selected: {_type},
                  showSelectedIcon: false,
                  onSelectionChanged: (value) =>
                      setState(() => _type = value.first),
                ),
                const SizedBox(height: 19),
                const _SectionLabel(title: 'Item details'),
                const SizedBox(height: 9),
                TextFormField(
                    controller: _title,
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: 80,
                    decoration: const InputDecoration(
                        labelText: 'What is it?',
                        hintText: 'e.g. Blue water bottle'),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                            ? 'Add a short item name'
                            : null),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: itemCategories
                      .map((value) =>
                          DropdownMenuItem(value: value, child: Text(value)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _description,
                    maxLines: 4,
                    maxLength: 700,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Color, brand, distinctive details…',
                        alignLabelWithHint: true),
                    validator: (value) =>
                        value == null || value.trim().length < 10
                            ? 'Add a few details to help identify it'
                            : null),
                const SizedBox(height: 8),
                const _SectionLabel(title: 'Where and when'),
                const SizedBox(height: 9),
                TextFormField(
                    controller: _location,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        labelText: 'Location',
                        hintText: 'Area, building, or nearby landmark',
                        prefixIcon: Icon(Icons.location_on_outlined)),
                    maxLength: 140,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Add a location'
                        : null),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                    onPressed: _chooseDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(
                        '${_type == 'lost' ? 'Lost' : 'Found'} on  ${_occurredAt.day}/${_occurredAt.month}/${_occurredAt.year}')),
                const SizedBox(height: 22),
                const _SectionLabel(
                    title: 'Add a photo',
                    subtitle:
                        'Optional, but it can help someone recognize it.'),
                const SizedBox(height: 9),
                InkWell(
                  onTap: _pickPhoto,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 170,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border)),
                    clipBehavior: Clip.antiAlias,
                    child: _photoBytes == null
                        ? const Center(
                            child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                Icon(Icons.add_photo_alternate_outlined,
                                    color: AppColors.teal, size: 30),
                                SizedBox(height: 8),
                                Text('Choose a photo',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.teal)),
                                Text('JPG, PNG or WebP',
                                    style: TextStyle(
                                        color: AppColors.muted, fontSize: 12))
                              ]))
                        : Stack(fit: StackFit.expand, children: [
                            Image.memory(_photoBytes!, fit: BoxFit.cover),
                            Positioned(
                                right: 8,
                                top: 8,
                                child: IconButton.filled(
                                    onPressed: () => setState(() {
                                          _photoBytes = null;
                                          _photoName = null;
                                        }),
                                    icon: const Icon(Icons.close),
                                    tooltip: 'Remove photo'))
                          ]),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: _busy ? null : _submit,
                        icon: _busy
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.campaign_outlined),
                        label: Text(_busy ? 'Publishing…' : 'Publish report'))),
              ]),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: AppColors.ink,
                fontSize: 16,
                fontWeight: FontWeight.w800)),
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(subtitle!,
              style: const TextStyle(color: AppColors.muted, fontSize: 12))
        ],
      ]);
}
