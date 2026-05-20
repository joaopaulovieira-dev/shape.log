import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shape_log/core/constants/app_colors.dart';
import 'package:shape_log/features/common/services/image_storage_service.dart';
import '../../../../core/utils/image_path_resolver.dart';
import '../../../../core/services/web_image_service.dart';
import '../../../image_library/presentation/image_source_sheet.dart';
import '../../../../core/presentation/widgets/app_modals.dart';
import '../../domain/entities/exercise.dart';

class ExerciseFormPage extends StatefulWidget {
  final Exercise? initialExercise;

  const ExerciseFormPage({super.key, this.initialExercise});

  @override
  State<ExerciseFormPage> createState() => _ExerciseFormPageState();
}

class _ExerciseFormPageState extends State<ExerciseFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;
  late TextEditingController _urlController;
  late TextEditingController _equipController;
  late TextEditingController _techniqueController;
  int _restTime = 60;
  List<String> _imagePaths = [];

  ExerciseTypeEntity _selectedType = ExerciseTypeEntity.weight;
  late TextEditingController _cardioDurationController;
  late TextEditingController _cardioIntensityController;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _retrieveLostData();
      });
    }
    final ex = widget.initialExercise;
    _selectedType = ex?.type ?? ExerciseTypeEntity.weight;
    _nameController = TextEditingController(text: ex?.name ?? '');

    // Weight specific
    _setsController = TextEditingController(text: ex?.sets.toString() ?? '3');
    _repsController = TextEditingController(text: ex?.reps.toString() ?? '10');
    _weightController = TextEditingController(
      text: ex?.weight.toString() ?? '0',
    );

    // Cardio specific
    _cardioDurationController = TextEditingController(
      text: ex?.cardioDurationMinutes?.toString() ?? '30',
    );
    _cardioIntensityController = TextEditingController(
      text: ex?.cardioIntensity ?? '',
    );

    _urlController = TextEditingController(text: ex?.youtubeUrl ?? '');
    _equipController = TextEditingController(text: ex?.equipmentNumber ?? '');
    _techniqueController = TextEditingController(text: ex?.technique ?? '');
    _restTime = ex?.restTimeSeconds ?? 60;
    _imagePaths = ex != null ? List.from(ex.imagePaths) : [];
  }

  Future<void> _retrieveLostData() async {
    final LostDataResponse response = await ImageSourceSheet.picker
        .retrieveLostData();
    if (response.isEmpty) return;
    final storageService = ImageStorageService();
    if (response.file != null) {
      final savedPath = await storageService.saveImage(response.file!);
      setState(() {
        _imagePaths.add(savedPath);
      });
    } else if (response.files != null) {
      final savedPaths = await storageService.saveImages(response.files!);
      setState(() {
        _imagePaths.addAll(savedPaths);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    _cardioDurationController.dispose();
    _cardioIntensityController.dispose();
    _urlController.dispose();
    _equipController.dispose();
    _techniqueController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final exercise = Exercise(
      name: _nameController.text,
      type: _selectedType,
      // Common fields
      youtubeUrl: _urlController.text.isEmpty ? null : _urlController.text,
      imagePaths: _imagePaths,
      equipmentNumber: _equipController.text.isEmpty
          ? null
          : _equipController.text,
      technique: _techniqueController.text.isEmpty
          ? null
          : _techniqueController.text,
      isCompleted: widget.initialExercise?.isCompleted ?? false,
      restTimeSeconds: _restTime,

      // Weight fields
      sets: int.tryParse(_setsController.text) ?? 0,
      reps: _selectedType == ExerciseTypeEntity.weight
          ? (int.tryParse(_repsController.text) ?? 0)
          : 0,
      weight: _selectedType == ExerciseTypeEntity.weight
          ? (double.tryParse(_weightController.text) ?? 0)
          : 0,

      // Cardio fields
      cardioDurationMinutes: _selectedType == ExerciseTypeEntity.cardio
          ? (double.tryParse(_cardioDurationController.text) ?? 0)
          : null,
      cardioIntensity: _selectedType == ExerciseTypeEntity.cardio
          ? (_cardioIntensityController.text.isEmpty
                ? null
                : _cardioIntensityController.text)
          : null,
    );

    Navigator.pop(context, exercise);
  }

  // ── Web Layout ─────────────────────────────────────────────────────────────

  Widget _buildWebLayout(BuildContext context) {
    final isEdit = widget.initialExercise != null;
    final restLabel =
        '${(_restTime ~/ 60).toString().padLeft(2, '0')}:${(_restTime % 60).toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: const Color(0xFF080808),
      body: Column(
        children: [
          // Top bar
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.06))),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                  tooltip: 'Voltar',
                ),
                const SizedBox(width: 12),
                Text(
                  isEdit ? 'Editar Exercício' : 'Novo Exercício',
                  style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.check, size: 18),
                  label: Text('Salvar', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Form(
                    key: _formKey,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Coluna esquerda: dados principais ─────────────
                        Expanded(
                          flex: 5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Tipo
                              _webCard(
                                label: 'TIPO DE EXERCÍCIO',
                                child: SegmentedButton<ExerciseTypeEntity>(
                                  style: SegmentedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A1A1A),
                                    selectedBackgroundColor: AppColors.primary,
                                    selectedForegroundColor: Colors.black,
                                    foregroundColor: Colors.white70,
                                    side: BorderSide(color: Colors.white.withOpacity(0.06)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  segments: const [
                                    ButtonSegment(value: ExerciseTypeEntity.weight, label: Text('Musculação'), icon: Icon(Icons.fitness_center)),
                                    ButtonSegment(value: ExerciseTypeEntity.cardio, label: Text('Cardio'), icon: Icon(Icons.directions_run)),
                                  ],
                                  selected: {_selectedType},
                                  onSelectionChanged: (s) => setState(() => _selectedType = s.first),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Dados do exercício
                              _webCard(
                                label: 'DADOS DO EXERCÍCIO',
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _nameController,
                                      style: GoogleFonts.outfit(color: Colors.white),
                                      textCapitalization: TextCapitalization.words,
                                      decoration: _buildDecoration('Nome do Exercício', Icons.title),
                                      validator: (v) => v!.isEmpty ? 'Informe um nome' : null,
                                    ),
                                    const SizedBox(height: 12),
                                    if (_selectedType == ExerciseTypeEntity.weight) ...[
                                      Row(children: [
                                        Expanded(child: TextFormField(controller: _setsController, style: GoogleFonts.outfit(color: Colors.white), keyboardType: TextInputType.number, decoration: _buildDecoration('Séries', Icons.reorder))),
                                        const SizedBox(width: 12),
                                        Expanded(child: TextFormField(controller: _repsController, style: GoogleFonts.outfit(color: Colors.white), keyboardType: TextInputType.number, decoration: _buildDecoration('Reps', Icons.repeat))),
                                        const SizedBox(width: 12),
                                        Expanded(child: TextFormField(controller: _weightController, style: GoogleFonts.outfit(color: Colors.white), keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _buildDecoration('Carga (kg)', Icons.fitness_center))),
                                      ]),
                                    ] else ...[
                                      Row(children: [
                                        Expanded(child: TextFormField(controller: _setsController, style: GoogleFonts.outfit(color: Colors.white), keyboardType: TextInputType.number, decoration: _buildDecoration('Séries', Icons.reorder))),
                                        const SizedBox(width: 12),
                                        Expanded(child: TextFormField(controller: _cardioDurationController, style: GoogleFonts.outfit(color: Colors.white), keyboardType: TextInputType.number, decoration: _buildDecoration('Tempo (min)', Icons.timer_outlined))),
                                      ]),
                                      const SizedBox(height: 12),
                                      TextFormField(controller: _cardioIntensityController, style: GoogleFonts.outfit(color: Colors.white), decoration: _buildDecoration('Intensidade / Velocidade', Icons.speed_outlined, hintText: 'Ex: 8km/h ou Moderado')),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Descanso
                              _webCard(
                                label: 'TEMPO DE DESCANSO',
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                                  child: Text(restLabel, style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                ),
                                child: Column(
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [30, 45, 60, 90, 120, 180].map((time) {
                                        final isSelected = _restTime == time;
                                        return ChoiceChip(
                                          label: Text(time >= 60 ? '${time ~/ 60}m' : '${time}s'),
                                          selected: isSelected,
                                          selectedColor: AppColors.primary,
                                          checkmarkColor: Colors.black,
                                          labelStyle: GoogleFonts.outfit(color: isSelected ? Colors.black : Colors.white70, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                          backgroundColor: Colors.white.withOpacity(0.05),
                                          side: BorderSide(color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.08)),
                                          onSelected: (s) { if (s) setState(() => _restTime = time); },
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 12),
                                    SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 4,
                                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                        activeTrackColor: AppColors.primary,
                                        inactiveTrackColor: Colors.white.withOpacity(0.1),
                                        thumbColor: AppColors.primary,
                                      ),
                                      child: Slider(value: _restTime.toDouble(), min: 0, max: 300, divisions: 60, onChanged: (v) => setState(() => _restTime = v.toInt())),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        // ── Coluna direita: info adicional + imagens ──────
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _webCard(
                                label: 'INFORMAÇÕES ADICIONAIS',
                                child: Column(
                                  children: [
                                    TextFormField(controller: _equipController, style: GoogleFonts.outfit(color: Colors.white), decoration: _buildDecoration('Equipamento nº (Opcional)', Icons.grid_3x3, hintText: 'Número da máquina')),
                                    const SizedBox(height: 12),
                                    TextFormField(controller: _urlController, style: GoogleFonts.outfit(color: Colors.white), keyboardType: TextInputType.url, decoration: _buildDecoration('YouTube link (Opcional)', Icons.video_library_outlined)),
                                    const SizedBox(height: 12),
                                    TextFormField(controller: _techniqueController, style: GoogleFonts.outfit(color: Colors.white), maxLines: 4, decoration: _buildDecoration('Técnica / Observações', Icons.lightbulb_outline)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              _webCard(
                                label: 'GALERIA DE IMAGENS',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (_imagePaths.isNotEmpty) ...[
                                      SizedBox(
                                        height: 120,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: _imagePaths.length,
                                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                                          itemBuilder: (ctx, i) => Stack(
                                            children: [
                                              Container(
                                                width: 120,
                                                height: 120,
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                                                  image: DecorationImage(image: ImagePathResolver.resolveToImageProvider(_imagePaths[i]), fit: BoxFit.cover),
                                                ),
                                              ),
                                              Positioned(
                                                top: 4, right: 4,
                                                child: GestureDetector(
                                                  onTap: () => setState(() => _imagePaths.removeAt(i)),
                                                  child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Icon(Icons.close, size: 12, color: Colors.white)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final url = await WebImageService.pickAndUpload(WebImageService.folderExercises);
                                        if (url != null) setState(() => _imagePaths.add(url));
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                        side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      ),
                                      icon: const Icon(Icons.add_photo_alternate_outlined),
                                      label: Text('Adicionar Imagem', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _webCard({required String label, required Widget child, Widget? trailing}) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111111),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label, style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white38, letterSpacing: 1.2)),
                if (trailing != null) ...[const Spacer(), trailing],
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return _buildWebLayout(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. Premium Header
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              backgroundColor: AppColors.background,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 16),
                title: Text(
                  widget.initialExercise == null
                      ? 'Novo Exercício'
                      : 'Editar Exercício',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.white),
                  onPressed: _save,
                  tooltip: 'Salvar',
                ),
              ],
            ),

            // 2. Type Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: SegmentedButton<ExerciseTypeEntity>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E1E1E),
                    selectedBackgroundColor: AppColors.primary,
                    selectedForegroundColor: Colors.black,
                    foregroundColor: Colors.white70,
                    side: BorderSide(color: Colors.white.withOpacity(0.05)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ExerciseTypeEntity.weight,
                      label: Text('Musculação'),
                      icon: Icon(Icons.fitness_center),
                    ),
                    ButtonSegment(
                      value: ExerciseTypeEntity.cardio,
                      label: Text('Cardio'),
                      icon: Icon(Icons.directions_run),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<ExerciseTypeEntity> newSelection) {
                    setState(() {
                      _selectedType = newSelection.first;
                    });
                  },
                ),
              ),
            ),

            // 3. Main Info Section
            SliverToBoxAdapter(
              child: _buildFormCard(
                title: "DADOS DO EXERCÍCIO",
                children: [
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: _buildDecoration(
                      'Nome do Exercício',
                      Icons.title,
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => v!.isEmpty ? 'Informe um nome' : null,
                  ),
                  const SizedBox(height: 16),

                  if (_selectedType == ExerciseTypeEntity.weight) ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _setsController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: _buildDecoration(
                              'Séries',
                              Icons.reorder,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _repsController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: _buildDecoration('Reps', Icons.repeat),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _weightController,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: _buildDecoration(
                        'Carga (kg)',
                        Icons.fitness_center,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ] else ...[
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _setsController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: _buildDecoration(
                              'Séries',
                              Icons.reorder,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _cardioDurationController,
                            style: GoogleFonts.outfit(color: Colors.white),
                            decoration: _buildDecoration(
                              'Tempo (min)',
                              Icons.timer_outlined,
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cardioIntensityController,
                      style: GoogleFonts.outfit(color: Colors.white),
                      decoration: _buildDecoration(
                        'Intensidade / Velocidade',
                        Icons.speed_outlined,
                        hintText: 'Ex: 8km/h ou Moderado',
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 4. Details Section
            SliverToBoxAdapter(
              child: _buildFormCard(
                title: "INFORMAÇÕES ADICIONAIS",
                children: [
                  TextFormField(
                    controller: _equipController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: _buildDecoration(
                      'Equipamento nº (Opcional)',
                      Icons.grid_3x3,
                      hintText: 'Número da máquina',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _urlController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    decoration: _buildDecoration(
                      'YouTube link (Opcional)',
                      Icons.video_library_outlined,
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _techniqueController,
                    style: GoogleFonts.outfit(color: Colors.white),
                    maxLines: 3,
                    decoration: _buildDecoration(
                      'Técnica / Observações',
                      Icons.lightbulb_outline,
                    ),
                  ),
                ],
              ),
            ),

            // 5. Rest Time Section
            SliverToBoxAdapter(
              child: _buildFormCard(
                title: "TEMPO DE DESCANSO",
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(_restTime ~/ 60).toString().padLeft(2, '0')}:${(_restTime % 60).toString().padLeft(2, '0')}',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                children: [
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [30, 45, 60, 90, 120, 180].map((time) {
                        final isSelected = _restTime == time;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              time >= 60 ? '${time ~/ 60}m' : '${time}s',
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            checkmarkColor: Colors.black,
                            labelStyle: GoogleFonts.outfit(
                              color: isSelected ? Colors.black : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            backgroundColor: const Color(0xFF2C2C2C),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.white.withOpacity(0.05),
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _restTime = time);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 16,
                      ),
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: Colors.white.withOpacity(0.1),
                      thumbColor: AppColors.primary,
                    ),
                    child: Slider(
                      value: _restTime.toDouble(),
                      min: 0,
                      max: 300,
                      divisions: 60,
                      onChanged: (value) =>
                          setState(() => _restTime = value.toInt()),
                    ),
                  ),
                ],
              ),
            ),

            // 6. Image Section
            SliverToBoxAdapter(
              child: _buildFormCard(
                title: "GALERIA DE IMAGENS",
                children: [
                  if (_imagePaths.isNotEmpty) ...[
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _imagePaths.length,
                        itemBuilder: (context, index) {
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 140,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.05),
                                  ),
                                  image: DecorationImage(
                                    image: ImagePathResolver.resolveToImageProvider(
                                      _imagePaths[index],
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 16,
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _imagePaths.removeAt(index),
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        if (kIsWeb) {
                          final url = await WebImageService.pickAndUpload(
                            WebImageService.folderExercises,
                          );
                          if (url != null) setState(() => _imagePaths.add(url));
                        } else {
                          await AppModals.showAppModal(
                            context: context,
                            title: 'Selecionar Imagem',
                            child: const ImageSourceSheet(),
                          ).then((files) async {
                            if (files != null && files is List<File>) {
                              final storageService = ImageStorageService();
                              final savedPaths = await storageService.saveImages(
                                files.map((file) => XFile(file.path)).toList(),
                              );
                              setState(() {
                                _imagePaths.addAll(savedPaths);
                              });
                            }
                          });
                        }
                      },
                      icon: const Icon(Icons.add_a_photo_outlined, size: 20),
                      label: Text(
                        'ADICIONAR FOTO',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required List<Widget> children,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 1.2,
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  InputDecoration _buildDecoration(
    String label,
    IconData icon, {
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
      hintText: hintText,
      hintStyle: GoogleFonts.outfit(color: Colors.grey[700], fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: Colors.black.withOpacity(0.2),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.02)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
    );
  }
}
