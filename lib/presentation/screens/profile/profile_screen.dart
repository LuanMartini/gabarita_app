import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/session_provider.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
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
    return Consumer2<UserProvider, SessionProvider>(
      builder: (context, userProvider, sessionProvider, _) {
        final user = userProvider.user;
        final name = user?.name ?? 'Lucas Mendes';
        final initials = _initials(name);
        final avatarData = _avatarData(user?.avatar);
        final avatarVersion = userProvider.avatarVersion;
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
                  CircleAvatar(
                    key: ValueKey(
                      'profile-avatar-${avatarData?.fingerprint ?? initials}-$avatarVersion',
                    ),
                    radius: 44,
                    backgroundColor: const Color(0xFF4DA3FF),
                    child: avatarData == null
                        ? Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : ClipOval(
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
                  TextButton.icon(
                    onPressed:
                        user == null ? null : () => _showEditNameDialog(name),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar nome'),
                  ),
                  const SizedBox(height: 22),
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

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'LM';
    final first = parts.first.substring(0, 1);
    final second = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return '$first$second'.toUpperCase();
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

  Future<void> _showEditNameDialog(
    String currentName,
  ) async {
    final newName = await showDialog<String>(
      context: context,
      builder: (_) => _EditNameDialog(currentName: currentName),
    );

    if (!mounted || newName == null) return;

    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    await _saveProfileName(newName);
  }

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nao foi possivel atualizar o nome.'),
        ),
      );
    }
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

class _EditNameDialog extends StatefulWidget {
  const _EditNameDialog({required this.currentName});

  final String currentName;

  @override
  State<_EditNameDialog> createState() => _EditNameDialogState();
}

class _EditNameDialogState extends State<_EditNameDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }
}
