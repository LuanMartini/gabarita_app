import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/entities/question.dart';
import '../../../services/hardware/camera_service.dart';
import '../../../services/widgets/home_widget_service.dart';
import '../../providers/questions_provider.dart';
import '../../providers/user_provider.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cameraService = CameraService();
  final _statementController = TextEditingController();
  final _subjectController = TextEditingController(text: 'Matematica');
  final _topicController = TextEditingController(text: 'Questao escaneada');
  final _optionAController = TextEditingController();
  final _optionBController = TextEditingController();
  final _optionCController = TextEditingController();
  final _optionDController = TextEditingController();
  final _optionEController = TextEditingController();
  final _explanationController = TextEditingController();

  ScannedQuestionImage? _scannedImage;
  int _difficulty = 2;
  String _correctOption = 'A';
  bool _isScanning = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _statementController.dispose();
    _subjectController.dispose();
    _topicController.dispose();
    _optionAController.dispose();
    _optionBController.dispose();
    _optionCController.dispose();
    _optionDController.dispose();
    _optionEController.dispose();
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scanner de questoes'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScannerImageCard(
                  image: _scannedImage,
                  isScanning: _isScanning,
                  onScan: _scanQuestion,
                ),
                const SizedBox(height: 16),
                _Field(
                  controller: _statementController,
                  label: 'Enunciado',
                  icon: Icons.subject_outlined,
                  maxLines: 5,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _Field(
                        controller: _subjectController,
                        label: 'Categoria',
                        icon: Icons.category_outlined,
                        validator: _required,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _Field(
                        controller: _topicController,
                        label: 'Topico',
                        icon: Icons.bookmark_outline,
                        validator: _required,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: _difficulty,
                        dropdownColor: const Color(0xFF0E131B),
                        decoration: _decoration(
                          label: 'Dificuldade',
                          icon: Icons.speed_outlined,
                        ),
                        style: const TextStyle(color: Colors.white),
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Facil')),
                          DropdownMenuItem(value: 2, child: Text('Media')),
                          DropdownMenuItem(value: 3, child: Text('Dificil')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _difficulty = value);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _correctOption,
                        dropdownColor: const Color(0xFF0E131B),
                        decoration: _decoration(
                          label: 'Gabarito',
                          icon: Icons.check_circle_outline,
                        ),
                        style: const TextStyle(color: Colors.white),
                        items: const ['A', 'B', 'C', 'D', 'E']
                            .map(
                              (option) => DropdownMenuItem(
                                value: option,
                                child: Text(option),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _correctOption = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Field(
                  controller: _optionAController,
                  label: 'Alternativa A',
                  icon: Icons.looks_one_outlined,
                  validator: _required,
                ),
                const SizedBox(height: 10),
                _Field(
                  controller: _optionBController,
                  label: 'Alternativa B',
                  icon: Icons.looks_two_outlined,
                  validator: _required,
                ),
                const SizedBox(height: 10),
                _Field(
                  controller: _optionCController,
                  label: 'Alternativa C',
                  icon: Icons.looks_3_outlined,
                  validator: _required,
                ),
                const SizedBox(height: 10),
                _Field(
                  controller: _optionDController,
                  label: 'Alternativa D',
                  icon: Icons.looks_4_outlined,
                  validator: _required,
                ),
                const SizedBox(height: 10),
                _Field(
                  controller: _optionEController,
                  label: 'Alternativa E opcional',
                  icon: Icons.looks_5_outlined,
                ),
                const SizedBox(height: 12),
                _Field(
                  controller: _explanationController,
                  label: 'Explicacao opcional',
                  icon: Icons.lightbulb_outline,
                  maxLines: 3,
                ),
                const SizedBox(height: 18),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveQuestion,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(_isSaving ? 'Salvando...' : 'Salvar no banco'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4DA3FF),
                    foregroundColor: Colors.white,
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
      ),
    );
  }

  Future<void> _scanQuestion() async {
    setState(() => _isScanning = true);
    try {
      final image = await _cameraService.scanQuestion();
      if (!mounted || image == null) return;
      setState(() => _scannedImage = image);
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final question = Question(
      text: _statementController.text.trim(),
      subject: _subjectController.text.trim(),
      topic: _topicController.text.trim(),
      difficulty: _difficulty,
      examSource: 'Scanner',
      optionA: _optionAController.text.trim(),
      optionB: _optionBController.text.trim(),
      optionC: _optionCController.text.trim(),
      optionD: _optionDController.text.trim(),
      optionE: _optionEController.text.trim().isEmpty
          ? null
          : _optionEController.text.trim(),
      correctOption: _correctOption,
      explanation: _explanationController.text.trim().isEmpty
          ? null
          : _explanationController.text.trim(),
      imagePath: null,
    );

    try {
      final provider = context.read<QuestionsProvider>();
      final questionId = await provider.addLocalQuestion(question);
      if (!mounted) return;

      if (questionId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nao foi possivel salvar a questao.')),
        );
        return;
      }

      await HomeWidgetService.refreshWidgets(
        userId: context.read<UserProvider>().userId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Questao adicionada ao banco local.')),
      );
      final popped = await Navigator.of(context).maybePop();
      if (!popped && mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'Campo obrigatorio';
    return null;
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF9BAABD)),
      filled: true,
      fillColor: const Color(0xFF0E131B),
      prefixIcon: Icon(icon, color: const Color(0xFF6F7D90)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF213047)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF4DA3FF)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
    );
  }
}

class _ScannerImageCard extends StatelessWidget {
  const _ScannerImageCard({
    required this.image,
    required this.isScanning,
    required this.onScan,
  });

  final ScannedQuestionImage? image;
  final bool isScanning;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Foto da questao',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isScanning ? null : onScan,
                  icon: isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt_outlined),
                  label: Text(isScanning ? 'Abrindo...' : 'Camera'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A2535),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: image == null
                    ? Container(
                        color: const Color(0xFF05070A),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.document_scanner_outlined,
                          color: Color(0xFF6F7D90),
                          size: 42,
                        ),
                      )
                    : Image.file(
                        File(image!.path),
                        fit: BoxFit.cover,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF9BAABD)),
        filled: true,
        fillColor: const Color(0xFF0E131B),
        prefixIcon: Icon(icon, color: const Color(0xFF6F7D90)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF213047)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF4DA3FF)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }
}
