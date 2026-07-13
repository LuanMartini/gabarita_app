import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../../providers/user_provider.dart';

// Bloco 1 - tela de perfil.
// Mostra foto, nome, meta semanal, conquistas e historico recente.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // Bloco 2 - depois do primeiro frame, recarrega perfil e simulados.
    // Usamos addPostFrameCallback porque context.read em initState precisa
    // esperar a arvore de widgets estar pronta.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProvider>().refresh();
      context.read<SessionProvider>().loadRecentSimulados(
            userId: context.read<UserProvider>().userId,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Bloco 3 - Consumer2 escuta UserProvider e SessionProvider ao mesmo tempo.
    return Consumer2<UserProvider, SessionProvider>(
      builder: (context, userProvider, sessionProvider, _) {
        // Bloco 4 - dados basicos do perfil.
        final user = userProvider.user;
        final name = user?.name ?? 'Lucas Mendes';
        final initials = _initials(name);

        // Bloco 5 - transforma avatar salvo no banco em bytes para Image.memory.
        final avatarData = _avatarData(user?.avatar);

        // Bloco 6 - avatarVersion muda sempre que a foto muda.
        // Isso ajuda o Flutter a recriar a imagem e nao mostrar cache antigo.
        final avatarVersion = userProvider.avatarVersion;

        // Bloco 7 - porcentagens exibidas na tela.
        final weeklyPercent = (userProvider.weeklyGoalProgress * 100).round();
        final accuracyPercent = (userProvider.accuracyRate * 100).round();

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 96),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Bloco 8 - CircleAvatar obrigatorio do perfil.
                  CircleAvatar(
                    // Bloco 9 - chave muda quando os bytes da foto mudam.
                    key: ValueKey(
                      'profile-avatar-${avatarData?.fingerprint ?? initials}-$avatarVersion',
                    ),
                    radius: 44,
                    backgroundColor: const Color(0xFF4DA3FF),
                    child: avatarData == null
                        // Bloco 10 - sem foto, mostra iniciais do usuario.
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : ClipOval(
                            // Bloco 11 - com foto, mostra bytes em memoria.
                            // Nao usamos FileImage para evitar cache de arquivo antigo.
                            child: Image.memory(
                              avatarData.bytes,
                              key: ValueKey(
                                'profile-avatar-image-${avatarData.fingerprint}-$avatarVersion',
                              ),
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              gaplessPlayback: false,
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  // Bloco 12 - abre tela propria para tirar/remover foto.
                  TextButton.icon(
                    onPressed: user == null
                        ? null
                        : () async {
                            final profileProvider =
                                context.read<UserProvider>();
                            await Navigator.of(context).pushNamed(
                              '/profile-photo',
                            );
                            if (!mounted) return;
                            // Bloco 13 - ao voltar, recarrega o usuario do banco.
                            await profileProvider.refresh(
                              userId: profileProvider.userId,
                            );
                          },
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Alterar foto'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Bloco 14 - botao para editar nome em dialog.
                  TextButton.icon(
                    onPressed:
                        user == null ? null : () => _showEditNameDialog(name),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar nome'),
                  ),
                  const SizedBox(height: 22),
                  // Bloco 15 - card da meta semanal.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E131B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF213047)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Meta Semanal',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              '$weeklyPercent%',
                              style: const TextStyle(
                                color: Color(0xFF4DA3FF),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${userProvider.weeklyAnsweredQuestions} de ${userProvider.weeklyGoalQuestions} questoes - faltam ${userProvider.remainingWeeklyQuestions}',
                          style: const TextStyle(color: Color(0xFF9BAABD)),
                        ),
                        const SizedBox(height: 12),
                        // Bloco 16 - LinearProgressIndicator exigido no perfil.
                        LinearProgressIndicator(
                          value: userProvider.weeklyGoalProgress,
                          minHeight: 8,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(8)),
                          backgroundColor: const Color(0xFF223044),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF4DA3FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Bloco 17 - card de conquistas/gamificacao.
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Conquistas',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              // Bloco 18 - Chip de ofensiva.
                              Expanded(
                                child: Chip(
                                  avatar: const Icon(
                                    Icons.local_fire_department,
                                  ),
                                  label: Text(
                                    '${userProvider.currentStreak} dias',
                                  ),
                                  backgroundColor: const Color(0xFF142C1F),
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Bloco 19 - Chip de taxa de acerto.
                              Expanded(
                                child: Chip(
                                  avatar: const Icon(Icons.center_focus_strong),
                                  label: Text('$accuracyPercent% acerto'),
                                  backgroundColor: const Color(0xFF122D47),
                                  labelStyle: const TextStyle(
                                    color: Color(0xFF4DA3FF),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Historico do mes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Bloco 20 - historico do mes em lista.
                  ListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.quiz_outlined,
                          color: Color(0xFF4DA3FF),
                        ),
                        title: Text(
                          '${userProvider.totalAnswered} questoes respondidas',
                        ),
                        subtitle: const Text('Total acumulado'),
                        trailing: Text('$accuracyPercent%'),
                      ),
                      // Bloco 21 - mostra ate 3 simulados recentes.
                      ...sessionProvider.recentSimulados.take(3).map((session) {
                        return ListTile(
                          leading: const Icon(
                            Icons.assignment_turned_in_outlined,
                            color: Color(0xFF22C55E),
                          ),
                          title: const Text('Simulado ENEM finalizado'),
                          subtitle: Text('${session.totalQuestions} questoes'),
                          trailing: Text('${session.scorePercentage}%'),
                        );
                      }),
                      ListTile(
                        leading: const Icon(
                          Icons.local_fire_department_outlined,
                          color: Color(0xFFF59E0B),
                        ),
                        title: Text(
                          'Maior sequencia: ${userProvider.maxStreak} dias',
                        ),
                        subtitle: const Text('Gamificacao'),
                        trailing: const Text('Streak'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Bloco 22 - calcula as iniciais do nome.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'LM';
    final first = parts.first.substring(0, 1);
    final second = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$second'.toUpperCase();
  }

  // Bloco 23 - converte o valor salvo de avatar em bytes.
  // O valor pode ser data URI novo ou caminho de arquivo antigo.
  _AvatarData? _avatarData(String? avatarPath) {
    // Bloco 24 - sem valor salvo, nao ha foto.
    if (avatarPath == null || avatarPath.trim().isEmpty) return null;

    // Bloco 25 - primeiro tenta formato novo: data:image/...;base64.
    final dataUri = _avatarDataFromDataUri(avatarPath);
    if (dataUri != null) return dataUri;

    // Bloco 26 - fallback para caminhos antigos de arquivo.
    final file = File(avatarPath);
    if (!file.existsSync()) return null;

    try {
      // Bloco 27 - fingerprint usa tamanho e data do arquivo para quebrar cache.
      final stat = file.statSync();
      final bytes = file.readAsBytesSync();
      if (bytes.isEmpty) return null;

      return _AvatarData(
        bytes: bytes,
        fingerprint:
            '$avatarPath-${stat.size}-${stat.modified.microsecondsSinceEpoch}',
      );
    } catch (_) {
      // Bloco 28 - se nao conseguiu ler, simplesmente mostra iniciais.
      return null;
    }
  }

  // Bloco 29 - decodifica data URI base64 salvo no banco.
  _AvatarData? _avatarDataFromDataUri(String value) {
    const marker = ';base64,';
    final markerIndex = value.indexOf(marker);
    // Bloco 30 - valida se parece uma imagem em base64.
    if (!value.startsWith('data:image/') || markerIndex < 0) return null;

    try {
      // Bloco 31 - decodifica apenas a parte depois de ";base64,".
      final bytes = base64Decode(value.substring(markerIndex + marker.length));
      if (bytes.isEmpty) return null;

      // Bloco 32 - fingerprint muda quando o conteudo muda.
      return _AvatarData(
        bytes: bytes,
        fingerprint: 'inline-avatar-${bytes.length}-${value.hashCode}',
      );
    } catch (_) {
      // Bloco 33 - base64 quebrado nao deve derrubar a tela.
      return null;
    }
  }

  // Bloco 34 - abre o dialog de edicao de nome.
  Future<void> _showEditNameDialog(
    String currentName,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(currentName: currentName),
    );

    if (!mounted || newName == null) return;

    // Bloco 35 - pequeno atraso evita conflito visual ao fechar o dialog.
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    await _saveProfileName(newName);
  }

  // Bloco 36 - salva o novo nome chamando o UserProvider.
  Future<void> _saveProfileName(String newName) async {
    try {
      await context.read<UserProvider>().updateName(newName);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome atualizado com sucesso.'),
        ),
      );
    } catch (_) {
      // Bloco 37 - erro amigavel em vez de tela vermelha.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel atualizar o nome.'),
        ),
      );
    }
  }
}

// Bloco 38 - objeto auxiliar para imagem de perfil ja decodificada.
class _AvatarData {
  const _AvatarData({
    required this.bytes,
    required this.fingerprint,
  });

  final Uint8List bytes;
  final String fingerprint;
}

// Bloco 39 - dialog separado para editar nome com validacao.
class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.currentName});

  final String currentName;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  // Bloco 40 - chave do formulario para validar antes de salvar.
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Bloco 41 - controller do campo de texto.
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Bloco 42 - inicia o campo com o nome atual.
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    // Bloco 43 - libera controller quando dialog fecha.
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar nome'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          maxLength: 30,
          decoration: const InputDecoration(labelText: 'Nome'),
          validator: (value) {
            // Bloco 44 - validacao simples para evitar nome vazio/curto/longo.
            final name = value?.trim() ?? '';
            if (name.isEmpty) return 'Informe seu nome.';
            if (name.length < 3 || name.length > 30) {
              return 'Use entre 3 e 30 caracteres.';
            }
            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  // Bloco 45 - valida e devolve o nome para a tela principal.
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }
}
