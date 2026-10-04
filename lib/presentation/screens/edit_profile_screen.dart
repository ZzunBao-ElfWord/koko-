import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../data/models/user.dart';
import '../../domain/states/app_state.dart';
import '../providers/app_provider.dart';
import '../../l10n/app_localizations.dart';

/// Edit current user profile screen.
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _statusTextController = TextEditingController();

  String _presence = 'online';
  bool _isLoading = false;
  bool _isSaving = false;
  Uint8List? _pendingAvatarBytes;
  String? _pendingAvatarName;

  // _presenceOptions moved to build() where context is available

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final data = await api.fetchSelf();
      final user = User.fromJson(data);

      _usernameController.text = user.username;
      _displayNameController.text = user.displayName ?? '';
      _statusTextController.text = user.status?.text ?? '';
      _presence = user.status?.presence ?? 'online';

      // Update cache
      ref.read(usersCacheProvider.notifier).update((state) {
        return {...state, user.id: user};
      });
      ref.read(currentUserProvider.notifier).state = user;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.loadFailed}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (picked == null) return;

    try {
      final bytes = await picked.readAsBytes();
      if (mounted) {
        setState(() {
          _pendingAvatarBytes = bytes;
          _pendingAvatarName = picked.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.readImageFailed}: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final api = ref.read(apiClientProvider);

      // Upload avatar if changed
      String? newAvatarId;
      if (_pendingAvatarBytes != null && _pendingAvatarName != null) {
        final attachment = await api.uploadAttachment(
          _pendingAvatarName!,
          _pendingAvatarBytes!,
        );
        newAvatarId = attachment.id;
      }

      // Build update data
      final updateData = <String, dynamic>{};
      if (newAvatarId != null) {
        updateData['avatar'] = newAvatarId;
      }
      if (_displayNameController.text.trim().isNotEmpty) {
        updateData['display_name'] = _displayNameController.text.trim();
      }

      if (updateData.isNotEmpty) {
        await api.editSelf(updateData);
      }

      // Update status
      await api.changeStatus(
        text: _statusTextController.text.trim().isNotEmpty ? _statusTextController.text.trim() : null,
        presence: _presence,
      );

      // Refresh user data
      final data = await api.fetchSelf();
      final user = User.fromJson(data);
      ref.read(currentUserProvider.notifier).state = user;
      ref.read(usersCacheProvider.notifier).update((state) {
        return {...state, user.id: user};
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileSaved)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.saveFailed}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final _presenceOptions = [
      {'value': 'online', 'label': AppLocalizations.of(context)!.online, 'icon': Icons.circle, 'color': AppTheme.successColor},
      {'value': 'idle', 'label': AppLocalizations.of(context)!.idle, 'icon': Icons.access_time, 'color': Colors.orange},
      {'value': 'busy', 'label': AppLocalizations.of(context)!.busy, 'icon': Icons.do_not_disturb_on, 'color': AppTheme.errorColor},
      {'value': 'invisible', 'label': AppLocalizations.of(context)!.invisible, 'icon': Icons.visibility_off, 'color': Colors.grey},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editProfile),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(AppLocalizations.of(context)!.save),
            ),
        ],
      ),
      body: _isLoading && user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: _getAvatarColor(user?.id ?? ''),
                          backgroundImage: (_pendingAvatarBytes != null && _pendingAvatarBytes!.isNotEmpty)
                              ? MemoryImage(_pendingAvatarBytes!) as ImageProvider
                              : (user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null),
                          onBackgroundImageError: (_, __) {},
                          child: Text(
                            _getInitials(user),
                            style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Username (read-only)
                  TextField(
                    controller: _usernameController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.username,
                      helperText: AppLocalizations.of(context)!.usernameReadonly,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Display name
                  TextField(
                    controller: _displayNameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.displayNameLabel,
                      hintText: AppLocalizations.of(context)!.displayNameHint,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Status text
                  TextField(
                    controller: _statusTextController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.statusTextLabel,
                      hintText: AppLocalizations.of(context)!.statusTextHint,
                      border: OutlineInputBorder(),
                    ),
                    maxLength: 128,
                  ),
                  const SizedBox(height: 16),
                  // Presence selector
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      AppLocalizations.of(context)!.presenceTitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._presenceOptions.map((opt) => RadioListTile<String>(
                    title: Row(
                      children: [
                        Icon(opt['icon'] as IconData, color: opt['color'] as Color, size: 18),
                        const SizedBox(width: 8),
                        Text(opt['label'] as String),
                      ],
                    ),
                    value: opt['value'] as String,
                    groupValue: _presence,
                    onChanged: (value) {
                      if (value != null) setState(() => _presence = value);
                    },
                    dense: true,
                  )),
                ],
              ),
            ),
    );
  }

  String _getInitials(User? user) {
    final name = user?.displayNameOrUsername ?? '?';
    return name.substring(0, 1).toUpperCase();
  }

  Color _getAvatarColor(String authorId) {
    final colors = [
      Colors.red, Colors.green, Colors.blue, Colors.orange,
      Colors.purple, Colors.teal, Colors.pink, Colors.indigo,
    ];
    return colors[authorId.hashCode.abs() % colors.length];
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    _statusTextController.dispose();
    super.dispose();
  }
}
