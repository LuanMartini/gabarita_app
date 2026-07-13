import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/hardware/camera_service.dart';
import '../../providers/user_provider.dart';

class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({super.key});

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  final CameraService _cameraService = CameraService();
  bool _isCapturing = false;
  bool _isRemoving = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        final user = provider.user;
        final avatarData = _avatarData(user?.avatar);
        final avatarVersion = provider.avatarVersion;
        final initials = _initials(user?.name ?? 'Lucas Mendes');

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Foto de perfil'),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          CircleAvatar(
                            key: ValueKey(
                              'profile-photo-avatar-${avatarData?.fingerprint ?? initials}-$avatarVersion',
                            ),
                            radius: 76,
                            backgroundColor: const Color(0xFF4DA3FF),
                            child: avatarData == null
                                ? Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                : ClipOval(
                                    child: Image.memory(
                                      avatarData.bytes,
                                      key: ValueKey(
                                        'profile-photo-avatar-image-${avatarData.fingerprint}-$avatarVersion',
                                      ),
                                      width: 152,
                                      height: 152,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: false,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            user?.name ?? 'Perfil local',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Atualize sua foto usando a camera do celular.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF9BAABD),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: _isCapturing || user == null
                        ? null
                        : () => _capturePhoto(provider),
                    icon: _isCapturing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      _isCapturing ? 'Abrindo camera...' : 'Tirar foto',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DA3FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _isRemoving || avatarData == null || user == null
                        ? null
                        : () => _removePhoto(provider),
                    icon: _isRemoving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: const Text('Remover foto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF334761)),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _capturePhoto(UserProvider provider) async {
    setState(() => _isCapturing = true);

    try {
      final previousAvatar = provider.user?.avatar;
      final photo = await _cameraService.captureProfilePhoto();
      if (!mounted || photo == null) return;
      final storedAvatar = photo.dataUri;

      await _evictAvatarCache(previousAvatar);
      await provider.updateAvatar(storedAvatar);
      await _deleteOldAvatar(previousAvatar, currentAvatar: storedAvatar);
      await _deleteOldAvatar(photo.path);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil atualizada.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel atualizar a foto.')),
      );
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _removePhoto(UserProvider provider) async {
    setState(() => _isRemoving = true);

    try {
      final previousAvatar = provider.user?.avatar;
      await _evictAvatarCache(previousAvatar);
      await provider.clearAvatar();
      await _deleteOldAvatar(previousAvatar);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil removida.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel remover a foto.')),
      );
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  Future<void> _evictAvatarCache(String? avatarPath) async {
    if (_isDataUriAvatar(avatarPath)) return;

    final fileImage = _fileImage(avatarPath);
    if (fileImage != null) {
      await fileImage.evict();
    }
  }

  Future<void> _deleteOldAvatar(
    String? avatarPath, {
    String? currentAvatar,
  }) async {
    if (avatarPath == null || avatarPath.trim().isEmpty) return;
    if (_isDataUriAvatar(avatarPath)) return;
    if (currentAvatar != null && avatarPath == currentAvatar) return;

    try {
      final file = File(avatarPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // A troca de foto ja foi salva; falha ao limpar arquivo antigo nao
      // deve bloquear o perfil.
    }
  }

  FileImage? _fileImage(String? avatarPath) {
    if (avatarPath == null || avatarPath.trim().isEmpty) return null;
    if (_isDataUriAvatar(avatarPath)) return null;

    final file = File(avatarPath);
    if (!file.existsSync()) return null;

    return FileImage(file);
  }

  _AvatarData? _avatarData(String? avatarPath) {
    if (avatarPath == null || avatarPath.trim().isEmpty) return null;

    final dataUri = _avatarDataFromDataUri(avatarPath);
    if (dataUri != null) return dataUri;

    final file = File(avatarPath);
    if (!file.existsSync()) return null;

    try {
      final stat = file.statSync();
      final bytes = file.readAsBytesSync();
      if (bytes.isEmpty) return null;

      return _AvatarData(
        bytes: bytes,
        fingerprint:
            '$avatarPath-${stat.size}-${stat.modified.microsecondsSinceEpoch}',
      );
    } catch (_) {
      return null;
    }
  }

  _AvatarData? _avatarDataFromDataUri(String value) {
    const marker = ';base64,';
    final markerIndex = value.indexOf(marker);
    if (!value.startsWith('data:image/') || markerIndex < 0) return null;

    try {
      final bytes = base64Decode(value.substring(markerIndex + marker.length));
      if (bytes.isEmpty) return null;

      return _AvatarData(
        bytes: bytes,
        fingerprint: 'inline-avatar-${bytes.length}-${value.hashCode}',
      );
    } catch (_) {
      return null;
    }
  }

  bool _isDataUriAvatar(String? value) {
    return value != null && value.startsWith('data:image/');
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'LM';

    final first = parts.first.substring(0, 1);
    final second = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$second'.toUpperCase();
  }
}

class _AvatarData {
  const _AvatarData({
    required this.bytes,
    required this.fingerprint,
  });

  final Uint8List bytes;
  final String fingerprint;
}
