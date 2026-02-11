import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/enums/activity_level.dart';
import '../../domain/enums/diet_type.dart';
import '../providers/user_profile_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/presentation/widgets/app_modals.dart';
import '../../../image_library/presentation/image_source_sheet.dart';
import '../../../common/services/image_storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class EditProfilePage extends ConsumerStatefulWidget {
  final bool isFirstRun; // If true, don't show "Cancel" button, force save

  const EditProfilePage({super.key, this.isFirstRun = false});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController(); // Target Weight

  double _height = 1.75; // Default height
  ActivityLevel _activityLevel = ActivityLevel.moderate;
  DietType _dietType = DietType.maintenance;
  String? _profilePicturePath;
  final Set<String> _limitations = {};

  final List<String> _availableLimitations = [
    "Joelho",
    "Ombro",
    "Lombar",
    "Punho",
    "Tornozelo",
    "Quadril",
    "Hérnia",
  ];

  @override
  void initState() {
    super.initState();
    // Initial load for when we enter the page normally
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(userProfileProvider);
      state.whenData((profile) => _populateFields(profile));
    });
  }

  void _populateFields(UserProfile? profile) {
    if (profile == null) return;

    _nameController.text = profile.name;
    _ageController.text = profile.age.toString();
    _weightController.text = profile.targetWeight.toString();
    setState(() {
      _height = profile.height;
      _activityLevel = profile.activityLevel;
      _dietType = profile.dietType;
      _profilePicturePath = profile.profilePicturePath;
      _limitations.clear();
      _limitations.addAll(profile.limitations);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final profile = UserProfile(
        name: _nameController.text,
        age: int.parse(_ageController.text),
        height: _height,
        targetWeight: double.parse(_weightController.text.replaceAll(',', '.')),
        activityLevel: _activityLevel,
        limitations: _limitations.toList(),
        dietType: _dietType,
        profilePicturePath: _profilePicturePath,
      );

      ref.read(userProfileProvider.notifier).saveProfile(profile);

      if (widget.isFirstRun) {
        context.go('/'); // Navigate to home
      } else {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(userProfileProvider);

    // Listen for data changes (like after a restore) to re-populate fields
    ref.listen<AsyncValue<UserProfile?>>(userProfileProvider, (previous, next) {
      next.whenData((profile) {
        if (profile != null) {
          _populateFields(profile);
        }
      });
    });

    return profileState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(child: Text("Erro ao carregar perfil: $error")),
      ),
      data: (profile) => _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil Bio-Data"),
        leading: widget.isFirstRun ? null : const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              const Text(
                "Configure seus parâmetros",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Estes dados serão a base para todos os cálculos do app.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // PROFILE PHOTO
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: _profilePicturePath != null
                          ? FileImage(File(_profilePicturePath!))
                          : null,
                      child: _profilePicturePath == null
                          ? Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.black,
                          ),
                          onPressed: _pickProfilePhoto,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // NAME & AGE
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Nome",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Idade",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // HEIGHT SLIDER
              Text(
                "Altura: ${_height.toStringAsFixed(2)}m",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Slider(
                value: _height,
                min: 1.40,
                max: 2.20,
                divisions: 80, // 1cm steps (220-140)
                label: _height.toStringAsFixed(2),
                activeColor: AppColors.primary,
                onChanged: (v) => setState(() => _height = v),
              ),
              const SizedBox(height: 24),

              // TARGET WEIGHT
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: "Peso Meta (kg)",
                  border: OutlineInputBorder(),
                  suffixText: "kg",
                ),
                validator: (v) => v!.isEmpty ? "Obrigatório" : null,
              ),
              const SizedBox(height: 24),

              // DIET TYPE (Segmented)
              Text(
                "Objetivo Atual",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SegmentedButton<DietType>(
                segments: const [
                  ButtonSegment(
                    value: DietType.cutting,
                    label: Text("Perda"),
                    icon: Icon(Icons.arrow_downward),
                  ),
                  ButtonSegment(
                    value: DietType.maintenance,
                    label: Text("Manter"),
                    icon: Icon(Icons.balance),
                  ),
                  ButtonSegment(
                    value: DietType.bulking,
                    label: Text("Ganho"),
                    icon: Icon(Icons.fitness_center),
                  ),
                ],
                selected: {_dietType},
                onSelectionChanged: (Set<DietType> newSelection) {
                  setState(() {
                    _dietType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // ACTIVITY LEVEL
              Text(
                "Nível de Atividade",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<ActivityLevel>(
                value: _activityLevel,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: ActivityLevel.values.map((level) {
                  return DropdownMenuItem(
                    value: level,
                    child: Text(level.label),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _activityLevel = v!),
              ),
              const SizedBox(height: 24),

              // LIMITATIONS (Chips)
              Text(
                "Limitações / Lesões",
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: _availableLimitations.map((limitation) {
                  final isSelected = _limitations.contains(limitation);
                  return FilterChip(
                    label: Text(limitation),
                    selected: isSelected,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : Colors.white,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _limitations.add(limitation);
                        } else {
                          _limitations.remove(limitation);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 40),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text(
                    "SALVAR PERFIL",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfilePhoto() async {
    final result = await AppModals.showAppModal(
      context: context,
      title: 'Foto de Perfil',
      child: const ImageSourceSheet(showLibrary: false),
    );

    if (result != null && result is List<File> && result.isNotEmpty) {
      final file = result.first;
      final storageService = ImageStorageService();
      final permanentPath = await storageService.saveImage(
        XFile(file.path),
        subDir: 'profile_photos',
      );

      setState(() {
        _profilePicturePath = permanentPath;
      });
    }
  }
}
