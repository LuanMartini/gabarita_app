import 'dart:convert';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class CapturedProfilePhoto {
  // Bloco 1 - objeto que representa a foto capturada pela camera.
  // Ele guarda caminho temporario, nome, bytes e tipo do arquivo.
  const CapturedProfilePhoto({
    required this.path,
    required this.name,
    required this.bytes,
    required this.mimeType,
  });

  final String path;
  final String name;
  final Uint8List bytes;
  final String? mimeType;

  // Bloco 2 - transforma os bytes da imagem em uma string base64.
  // Isso permite salvar a foto diretamente no SQLite sem depender de arquivo.
  String get dataUri {
    // Bloco 2.1 - se o Android nao informar tipo, assumimos jpeg.
    final type =
        mimeType == null || mimeType!.trim().isEmpty ? 'image/jpeg' : mimeType!;

    // Bloco 2.2 - prefixo data:image informa que a string contem uma imagem.
    return 'data:$type;base64,${base64Encode(bytes)}';
  }

  // Bloco 3 - mapa usado apenas para debug/log se precisarmos inspecionar.
  Map<String, dynamic> toMap() {
    return {
      'path': path,
      'name': name,
      'bytes_length': bytes.length,
      'mime_type': mimeType,
    };
  }
}

class CameraService {
  // Bloco 4 - recebe ImagePicker por injecao opcional.
  // Nos testes daria para trocar o picker real por um falso.
  CameraService({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  // Bloco 5 - abre a camera e retorna a foto reduzida para perfil.
  // maxWidth/maxHeight deixam a imagem pequena para nao pesar no SQLite.
  Future<CapturedProfilePhoto?> captureProfilePhoto({
    double maxWidth = 360,
    double maxHeight = 360,
    int imageQuality = 70,
  }) async {
    // Bloco 5.1 - chama o plugin image_picker usando a camera do celular.
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      imageQuality: imageQuality,
    );

    // Bloco 5.2 - se o usuario cancelar a camera, nao ha foto para salvar.
    if (image == null) return null;

    // Bloco 5.3 - le os bytes diretamente do arquivo temporario retornado.
    // A foto final sera salva como base64, nao como caminho local.
    final bytes = await image.readAsBytes();

    // Bloco 5.4 - devolve um objeto simples para a tela usar.
    return CapturedProfilePhoto(
      path: image.path,
      name: image.name,
      bytes: bytes,
      mimeType: image.mimeType,
    );
  }
}
