import 'dart:typed_data';

import 'package:cod/classes/player.dart';
import 'package:cod/providers/player_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cod/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddPlayerScreen extends ConsumerStatefulWidget {
  const AddPlayerScreen({super.key});

  static const routeName = '/players/add';

  @override
  ConsumerState<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends ConsumerState<AddPlayerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  _PhotoSource? _selectedSource;

  bool get _canSave =>
      _nameController.text.trim().isNotEmpty && _imageBytes != null && _imageBytes!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Text('Add Player', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Player name', hintText: 'Enter name'),
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.words,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Give your player a name';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (_canSave) {
                        _savePlayer(context);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Photo for player',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _ImagePickerCard(
                          icon: Icons.photo_camera_outlined,
                          title: 'Use Camera',
                          subtitle: 'Take a new photo',
                          isSelected: _selectedSource == _PhotoSource.camera,
                          onTap: () => _pickImage(ImageSource.camera, _PhotoSource.camera),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _ImagePickerCard(
                          icon: Icons.photo_library_outlined,
                          title: 'Choose from Library',
                          subtitle: 'Pick from camera roll',
                          isSelected: _selectedSource == _PhotoSource.gallery,
                          onTap: () => _pickImage(ImageSource.gallery, _PhotoSource.gallery),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Preview',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(radius: 28, backgroundImage: _previewImage()),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _nameController.text.trim().isEmpty ? 'New Player' : _nameController.text.trim(),
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _imageBytes == null ? 'Pick a photo to personalize this player' : 'Ready to join the fun',
                              style: const TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _canSave ? () => _savePlayer(context) : null,
                    child: const Text('Save Player'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source, _PhotoSource tracker) async {
    try {
      final XFile? file = await _picker.pickImage(source: source, maxWidth: 600, imageQuality: 85);
      if (file == null) {
        return;
      }

      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _imageBytes = bytes;
        _selectedSource = tracker;
      });
    } on Exception catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick image: ${error.toString()}')));
    }
  }

  void _savePlayer(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final photoBytes = _imageBytes;
    if (photoBytes == null || photoBytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a photo to continue.')),
      );
      return;
    }

    final manager = ref.read(playerManagerProvider);
    manager.addPlayer(
      Player(
        name: _nameController.text.trim(),
        photoBytes: photoBytes,
      ),
    );
    Navigator.of(context).pop();
  }

  ImageProvider _previewImage() {
    if (_imageBytes != null && _imageBytes!.isNotEmpty) {
      return MemoryImage(_imageBytes!);
    }
    return const AssetImage(Player.defaultAvatarAsset);
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.isSelected,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Colors.white70),
            ),
            const SizedBox(height: 18),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.white60)),
          ],
        ),
      ),
    );
  }
}

enum _PhotoSource { camera, gallery }
