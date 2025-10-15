import 'package:cod/classes/player.dart';
import 'package:cod/classes/player_manager.dart';
import 'package:cod/theme/colors.dart';
import 'package:flutter/material.dart';

class AddPlayerScreen extends StatefulWidget {
  const AddPlayerScreen({super.key});

  static const routeName = '/players/add';

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedPhoto;
  _PhotoSource? _selectedSource;

  static const String _fallbackPhoto =
      'https://images.unsplash.com/photo-1487412912498-0447578fcca8?auto=format&fit=crop&w=200&q=60';

  static const List<String> _cameraSamples = [
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=60',
    'https://images.unsplash.com/photo-1520813792240-56fc4a3765a7?auto=format&fit=crop&w=200&q=60',
    'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=200&q=60',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=60',
  ];

  static const List<String> _librarySamples = [
    'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=200&q=60',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=200&q=60',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=60',
    'https://images.unsplash.com/photo-1544723795-3fb6469f5b39?auto=format&fit=crop&w=200&q=60',
  ];

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
    final canSave = _nameController.text.trim().isNotEmpty;

    return Scaffold(
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
                    if (canSave) {
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
                        onTap: () => _choosePhoto(context, _PhotoSource.camera),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _ImagePickerCard(
                        icon: Icons.photo_library_outlined,
                        title: 'Choose from Library',
                        subtitle: 'Pick from camera roll',
                        isSelected: _selectedSource == _PhotoSource.library,
                        onTap: () => _choosePhoto(context, _PhotoSource.library),
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
                      CircleAvatar(radius: 28, backgroundImage: NetworkImage(_selectedPhoto ?? _fallbackPhoto)),
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
                            _selectedPhoto == null
                                ? 'Pick a photo to personalize this player'
                                : 'Ready to join the fun',
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                  onPressed: canSave ? () => _savePlayer(context) : null,
                  child: const Text('Save Player'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _choosePhoto(BuildContext context, _PhotoSource source) async {
    final samples = source == _PhotoSource.camera ? _cameraSamples : _librarySamples;
    final title = source == _PhotoSource.camera ? 'Take a new photo' : 'Pick from camera roll';
    final selection = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return _PhotoPickerSheet(title: title, options: samples);
      },
    );

    if (selection == null) {
      return;
    }

    setState(() {
      _selectedPhoto = selection;
      _selectedSource = source;
    });
  }

  void _savePlayer(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final manager = PlayerScope.of(context);
    manager.addPlayer(Player(name: _nameController.text.trim(), photoUrl: _selectedPhoto ?? _fallbackPhoto));
    Navigator.of(context).pop();
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

class _PhotoPickerSheet extends StatelessWidget {
  const _PhotoPickerSheet({required this.title, required this.options});

  final String title;
  final List<String> options;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: GridView.builder(
                itemCount: options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemBuilder: (context, index) {
                  final photo = options[index];
                  return GestureDetector(
                    onTap: () => Navigator.of(context).pop(photo),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(photo, fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
            ),
          ],
        ),
      ),
    );
  }
}

enum _PhotoSource { camera, library }
