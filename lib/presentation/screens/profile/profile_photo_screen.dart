import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/hardware/camera_service.dart';
import '../../providers/user_provider.dart';

// Tela: ProfilePhotoScreen.
// Objetivo: permitir que o aluno tire uma foto nova, visualize o preview
// circular e remova a foto atual.
// A foto nova e salva como data URI base64 no banco local, evitando cache antigo.
class ProfilePhotoScreen extends StatefulWidget {
  const ProfilePhotoScreen({super.key});

  @override
  State<ProfilePhotoScreen> createState() => _ProfilePhotoScreenState();
}

class _ProfilePhotoScreenState extends State<ProfilePhotoScreen> {
  // Bloco 1 - servico responsavel por abrir a camera e devolver a foto.
  final CameraService _cameraService = CameraService();

  // Bloco 2 - flags de carregamento para impedir duplo clique nos botoes.
  bool _isCapturing = false;
  bool _isRemoving = false;

  @override
  Widget build(BuildContext context) {
    // Bloco 3 - Consumer escuta mudancas do UserProvider.
    // Quando a foto muda, o Provider chama notifyListeners e esta tela atualiza.
    return Consumer<UserProvider>(
      builder: (context, provider, _) {
        // Bloco 4 - dados basicos do perfil atual.
        final user = provider.user;

        // Bloco 5 - transforma o avatar salvo em bytes prontos para exibir.
        // Pode vir como base64 novo ou caminho antigo.
        final avatarData = _avatarData(user?.avatar);

        // Bloco 6 - versao visual usada para forcar rebuild da imagem.
        final avatarVersion = provider.avatarVersion;

        // Bloco 7 - iniciais aparecem quando ainda nao existe foto.
        final initials = _initials(user?.name ?? 'Lucas Mendes');

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Foto de perfil'),
          ),
          body: SafeArea(
            // Widget especial: SingleChildScrollView.
            // Mantem toda a tela rolavel se o teclado, barra do sistema ou
            // celular pequeno reduzirem o espaco vertical.
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bloco 8 - card principal com preview da foto atual.
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        children: [
                          // Bloco 9 - avatar grande.
                          // Se nao ha foto, mostra iniciais; se ha foto, mostra Image.memory.
                          // Widget especial: CircleAvatar.
                          // Cria o preview circular da foto do perfil.
                          CircleAvatar(
                            key: ValueKey(
                              'profile-photo-avatar-${avatarData?.fingerprint ?? initials}-$avatarVersion',
                            ),
                            radius: 76,
                            backgroundColor: const Color(0xFF4DA3FF),
                            child: avatarData == null
                                // Bloco 9.1 - fallback sem foto.
                                ? Text(
                                    initials,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 42,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  )
                                // Bloco 9.2 - foto real vinda dos bytes do banco.
                                : ClipOval(
                                    // Widget especial: ClipOval.
                                    // Recorta a imagem em formato circular para
                                    // encaixar perfeitamente dentro do avatar.
                                    child: Image.memory(
                                      // Widget especial: Image.memory.
                                      // Renderiza uma imagem usando bytes em memoria,
                                      // nao um arquivo cacheado.
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
                          // Bloco 10 - nome do usuario abaixo da foto.
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
                          // Bloco 11 - texto explicando a acao da tela.
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
                  // Bloco 12 - botao que abre a camera.
                  // Widget especial: ElevatedButton.icon.
                  // Botao de acao principal com icone + texto. Aqui abre a camera.
                  ElevatedButton.icon(
                    onPressed: _isCapturing || user == null
                        ? null
                        : () => _capturePhoto(provider),
                    icon: _isCapturing
                        // Bloco 12.1 - enquanto a camera abre/salva, mostra loading.
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            // Widget especial: CircularProgressIndicator.
                            // Indicador de carregamento circular usado enquanto
                            // a foto esta sendo capturada/salva.
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
                  // Bloco 13 - botao que remove a foto atual.
                  // Fica desabilitado se nao existe foto para remover.
                  // Widget especial: OutlinedButton.icon.
                  // Botao secundario com borda, ideal para acao menos principal
                  // como remover foto.
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

  // Bloco 14 - fluxo completo para tirar e salvar nova foto.
  Future<void> _capturePhoto(UserProvider provider) async {
    // Bloco 14.1 - liga loading do botao de camera.
    setState(() => _isCapturing = true);

    try {
      // Bloco 14.2 - guarda avatar anterior para limpar cache/arquivo antigo.
      final previousAvatar = provider.user?.avatar;

      // Bloco 14.3 - abre camera pelo servico.
      final photo = await _cameraService.captureProfilePhoto();

      // Bloco 14.4 - se usuario cancelou a camera, termina sem erro.
      if (!mounted || photo == null) return;

      // Bloco 14.5 - converte bytes da foto para data:image/...;base64.
      final storedAvatar = photo.dataUri;

      // Bloco 14.6 - limpa cache caso o avatar antigo fosse arquivo local.
      await _evictAvatarCache(previousAvatar);

      // Bloco 14.7 - salva no SQLite via Provider/UseCase e atualiza a tela.
      await provider.updateAvatar(storedAvatar);

      // Bloco 14.8 - tenta apagar arquivo antigo, se existia.
      await _deleteOldAvatar(previousAvatar, currentAvatar: storedAvatar);

      // Bloco 14.9 - tenta apagar o arquivo temporario retornado pela camera.
      await _deleteOldAvatar(photo.path);
      if (!mounted) return;

      // Bloco 14.10 - feedback visual para o usuario.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil atualizada.')),
      );
    } catch (_) {
      // Bloco 14.11 - qualquer falha mostra mensagem simples.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel atualizar a foto.')),
      );
    } finally {
      // Bloco 14.12 - desliga loading ao terminar, com sucesso ou erro.
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  // Bloco 15 - fluxo para remover foto atual.
  Future<void> _removePhoto(UserProvider provider) async {
    // Bloco 15.1 - liga loading do botao remover.
    setState(() => _isRemoving = true);

    try {
      // Bloco 15.2 - guarda avatar antigo antes de limpar do banco.
      final previousAvatar = provider.user?.avatar;

      // Bloco 15.3 - se avatar antigo era arquivo, remove do cache.
      await _evictAvatarCache(previousAvatar);

      // Bloco 15.4 - grava null no SQLite e atualiza Provider.
      await provider.clearAvatar();

      // Bloco 15.5 - se era arquivo local, tenta apagar do armazenamento.
      await _deleteOldAvatar(previousAvatar);
      if (!mounted) return;

      // Bloco 15.6 - avisa que removeu.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil removida.')),
      );
    } catch (_) {
      // Bloco 15.7 - se algo falhou, mostra mensagem sem derrubar app.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nao foi possivel remover a foto.')),
      );
    } finally {
      // Bloco 15.8 - desliga loading.
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  // Bloco 16 - remove imagem antiga do cache do Flutter se for arquivo local.
  Future<void> _evictAvatarCache(String? avatarPath) async {
    // Bloco 16.1 - avatar base64 nao usa FileImage, entao nao precisa evict.
    if (_isDataUriAvatar(avatarPath)) return;

    // Bloco 16.2 - se o caminho existe, pede para o Flutter esquecer a imagem.
    final fileImage = _fileImage(avatarPath);
    if (fileImage != null) {
      await fileImage.evict();
    }
  }

  // Bloco 17 - tenta apagar um arquivo antigo do aparelho.
  // So vale para avatares antigos que eram caminhos fisicos.
  Future<void> _deleteOldAvatar(
    String? avatarPath, {
    String? currentAvatar,
  }) async {
    // Bloco 17.1 - sem caminho, nao ha arquivo para apagar.
    if (avatarPath == null || avatarPath.trim().isEmpty) return;

    // Bloco 17.2 - base64 fica no banco; nao existe arquivo para apagar.
    if (_isDataUriAvatar(avatarPath)) return;

    // Bloco 17.3 - evita apagar a foto atual por engano.
    if (currentAvatar != null && avatarPath == currentAvatar) return;

    try {
      // Bloco 17.4 - se o arquivo existe, remove.
      final file = File(avatarPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // A troca de foto ja foi salva; falha ao limpar arquivo antigo nao
      // deve bloquear o perfil.
    }
  }

  // Bloco 18 - cria FileImage somente para avatar antigo salvo como caminho.
  FileImage? _fileImage(String? avatarPath) {
    // Bloco 18.1 - valida caminho.
    if (avatarPath == null || avatarPath.trim().isEmpty) return null;

    // Bloco 18.2 - se for base64, nao e arquivo.
    if (_isDataUriAvatar(avatarPath)) return null;

    // Bloco 18.3 - so retorna imagem se o arquivo ainda existe.
    final file = File(avatarPath);
    if (!file.existsSync()) return null;

    return FileImage(file);
  }

  // Bloco 19 - converte o avatar salvo em bytes para exibir.
  // Aceita tanto o formato novo base64 quanto o formato antigo por arquivo.
  _AvatarData? _avatarData(String? avatarPath) {
    // Bloco 19.1 - sem valor, nao ha avatar.
    if (avatarPath == null || avatarPath.trim().isEmpty) return null;

    // Bloco 19.2 - tenta ler como base64 novo.
    final dataUri = _avatarDataFromDataUri(avatarPath);
    if (dataUri != null) return dataUri;

    // Bloco 19.3 - fallback para avatar antigo salvo como caminho local.
    final file = File(avatarPath);
    if (!file.existsSync()) return null;

    try {
      // Bloco 19.4 - le bytes do arquivo antigo.
      final stat = file.statSync();
      final bytes = file.readAsBytesSync();
      if (bytes.isEmpty) return null;

      return _AvatarData(
        bytes: bytes,
        // Bloco 19.5 - fingerprint muda se caminho/tamanho/data mudarem.
        fingerprint:
            '$avatarPath-${stat.size}-${stat.modified.microsecondsSinceEpoch}',
      );
    } catch (_) {
      return null;
    }
  }

  // Bloco 20 - decodifica avatar salvo como data:image/...;base64.
  _AvatarData? _avatarDataFromDataUri(String value) {
    // Bloco 20.1 - separador entre metadados e base64.
    const marker = ';base64,';
    final markerIndex = value.indexOf(marker);

    // Bloco 20.2 - valida se a string tem o formato de imagem inline.
    if (!value.startsWith('data:image/') || markerIndex < 0) return null;

    try {
      // Bloco 20.3 - pega somente a parte depois de ;base64, e decodifica.
      final bytes = base64Decode(value.substring(markerIndex + marker.length));
      if (bytes.isEmpty) return null;

      return _AvatarData(
        bytes: bytes,
        // Bloco 20.4 - fingerprint identifica aquela imagem especifica.
        fingerprint: 'inline-avatar-${bytes.length}-${value.hashCode}',
      );
    } catch (_) {
      return null;
    }
  }

  // Bloco 21 - identifica se uma string representa imagem inline em base64.
  bool _isDataUriAvatar(String? value) {
    return value != null && value.startsWith('data:image/');
  }

  // Bloco 22 - gera as iniciais do nome para mostrar quando nao ha foto.
  String _initials(String name) {
    // Bloco 22.1 - divide nome por espacos.
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'LM';

    // Bloco 22.2 - usa primeira letra do primeiro e do ultimo nome.
    final first = parts.first.substring(0, 1);
    final second = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$second'.toUpperCase();
  }
}

// Bloco 23 - objeto auxiliar para carregar avatar na tela.
// Ele guarda bytes da imagem e um identificador para forcar rebuild.
class _AvatarData {
  const _AvatarData({
    required this.bytes,
    required this.fingerprint,
  });

  final Uint8List bytes;
  final String fingerprint;
}
