import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/enums/activity_level.dart';
import '../../domain/enums/diet_type.dart';
import '../../domain/enums/gender.dart';
import '../providers/user_profile_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/presentation/widgets/app_modals.dart';
import '../../../image_library/presentation/image_source_sheet.dart';
import '../../../common/services/image_storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
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
  Gender _gender = Gender.male;
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
      _gender = profile.gender;
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
        gender: _gender,
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
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: widget.isFirstRun
                ? null
                : const BackButton(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 16),
              title: Text(
                'Perfil Bio-Data',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormCard(
                      title: "DADOS PESSOAIS",
                      icon: Icons.person_outline,
                      children: [
                        // PROFILE PHOTO
                        Center(
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    width: 4,
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: const Color(0xFF2A2A2A),
                                  backgroundImage: _profilePicturePath != null
                                      ? FileImage(File(_profilePicturePath!))
                                      : null,
                                  child: _profilePicturePath == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey,
                                        )
                                      : null,
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickProfilePhoto,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // NAME
                        _buildTextField(
                          controller: _nameController,
                          label: "NOME",
                          icon: Icons.badge_outlined,
                          validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                        ),
                        const SizedBox(height: 20),

                        // AGE & GENDER
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _ageController,
                                label: "IDADE",
                                icon: Icons.cake_outlined,
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    v!.isEmpty ? "Obrigatório" : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(flex: 3, child: _buildGenderDropdown()),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildFormCard(
                      title: "PARÂMETROS CORPORAIS",
                      icon: Icons.straighten,
                      children: [
                        _buildHeightSlider(),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _weightController,
                          label: "PESO META (KG)",
                          icon: Icons.ads_click,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildFormCard(
                      title: "ESTILO DE VIDA",
                      icon: Icons.bolt,
                      children: [
                        _buildDietSelector(),
                        const SizedBox(height: 24),
                        _buildActivityDropdown(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    _buildFormCard(
                      title: "LIMITAÇÕES",
                      icon: Icons.warning_amber_rounded,
                      children: [_buildLimitationsChips()],
                    ),

                    const SizedBox(height: 40),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "SALVAR CONFIGURAÇÕES",
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600], size: 20),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 16,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildGenderDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "SEXO",
          style: GoogleFonts.outfit(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<Gender>(
          value: _gender,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E1E1E),
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(
              Icons.wc_outlined,
              color: Colors.grey[600],
              size: 20,
            ),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 16,
            ),
          ),
          items: Gender.values.map((g) {
            return DropdownMenuItem(
              value: g,
              child: Text(g.label, style: GoogleFonts.outfit(fontSize: 14)),
            );
          }).toList(),
          onChanged: (v) => setState(() => _gender = v!),
        ),
      ],
    );
  }

  Widget _buildHeightSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "ALTURA",
              style: GoogleFonts.outfit(
                color: Colors.grey[500],
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            Text(
              "${_height.toStringAsFixed(2)}m",
              style: GoogleFonts.outfit(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: Colors.white.withValues(alpha: 0.05),
            thumbColor: Colors.white,
            overlayColor: AppColors.primary.withValues(alpha: 0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: _height,
            min: 1.40,
            max: 2.20,
            divisions: 80,
            onChanged: (v) => setState(() => _height = v),
          ),
        ),
      ],
    );
  }

  Widget _buildDietSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "OBJETIVO ATUAL",
          style: GoogleFonts.outfit(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              _buildDietOption(DietType.cutting, "PERDA", Icons.arrow_downward),
              _buildDietOption(DietType.maintenance, "MANTER", Icons.balance),
              _buildDietOption(DietType.bulking, "GANHO", Icons.fitness_center),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDietOption(DietType type, String label, IconData icon) {
    final isSelected = _dietType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _dietType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.black : Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.black : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "NÍVEL DE ATIVIDADE",
          style: GoogleFonts.outfit(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ActivityLevel>(
          value: _activityLevel,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E1E1E),
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.bolt_outlined,
              color: Colors.grey[600],
              size: 20,
            ),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: ActivityLevel.values.map((level) {
            return DropdownMenuItem(
              value: level,
              child: Text(level.label, style: GoogleFonts.outfit()),
            );
          }).toList(),
          onChanged: (v) => setState(() => _activityLevel = v!),
        ),
      ],
    );
  }

  Widget _buildLimitationsChips() {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: _availableLimitations.map((limitation) {
        final isSelected = _limitations.contains(limitation);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _limitations.remove(limitation);
              } else {
                _limitations.add(limitation);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Text(
              limitation,
              style: GoogleFonts.outfit(
                color: isSelected ? AppColors.primary : Colors.grey[500],
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
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
