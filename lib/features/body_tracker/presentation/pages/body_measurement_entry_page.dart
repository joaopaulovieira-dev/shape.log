// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:body_part_selector/body_part_selector.dart';
import '../../domain/entities/body_measurement.dart';
import '../providers/body_tracker_provider.dart';
import '../widgets/bmi_gauge.dart';
import '../../../../core/constants/app_colors.dart';

class BodyMeasurementEntryPage extends ConsumerStatefulWidget {
  final BodyMeasurement? measurementToEdit;

  const BodyMeasurementEntryPage({super.key, this.measurementToEdit});

  @override
  ConsumerState<BodyMeasurementEntryPage> createState() =>
      _BodyMeasurementEntryPageState();
}

class _BodyMeasurementEntryPageState
    extends ConsumerState<BodyMeasurementEntryPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _dateController = TextEditingController();
  final _weightController = TextEditingController();

  // Measurement Controllers
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _bicepsRightController = TextEditingController();
  final _bicepsLeftController = TextEditingController();
  final _hipsController = TextEditingController();
  final _thighRightController = TextEditingController();
  final _thighLeftController = TextEditingController();
  final _calvesRightController = TextEditingController();
  final _calvesLeftController = TextEditingController();
  final _neckController = TextEditingController();
  final _shouldersController = TextEditingController(); // NEW
  final _forearmRightController = TextEditingController();
  final _forearmLeftController = TextEditingController();

  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  double _currentBMI = 0.0;

  // Body Part Selector State
  BodySide _selectedSide = BodySide.front;
  BodyParts _filledParts = const BodyParts();

  @override
  void initState() {
    super.initState();

    if (widget.measurementToEdit != null) {
      _loadExistingMeasurement(widget.measurementToEdit!);
    } else {
      _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    }

    _weightController.addListener(_calculateBMI);

    // Listeners for highlighting
    _waistController.addListener(_updateFilledParts);
    _chestController.addListener(_updateFilledParts);
    _bicepsRightController.addListener(_updateFilledParts);
    _bicepsLeftController.addListener(_updateFilledParts);
    _hipsController.addListener(_updateFilledParts);
    _thighRightController.addListener(_updateFilledParts);
    _thighLeftController.addListener(_updateFilledParts);
    _calvesRightController.addListener(_updateFilledParts);
    _calvesLeftController.addListener(_updateFilledParts);
    _neckController.addListener(_updateFilledParts);
    _shouldersController.addListener(_updateFilledParts);
    _forearmRightController.addListener(_updateFilledParts);
    _forearmLeftController.addListener(_updateFilledParts);
  }

  void _loadExistingMeasurement(BodyMeasurement measurement) {
    _selectedDate = measurement.date;
    _dateController.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    _weightController.text = measurement.weight.toString();
    _currentBMI = measurement.bmi ?? 0.0;

    _waistController.text = measurement.waistCircumference > 0
        ? measurement.waistCircumference.toString()
        : '';
    _chestController.text = measurement.chestCircumference > 0
        ? measurement.chestCircumference.toString()
        : '';
    _bicepsRightController.text = measurement.bicepsRight > 0
        ? measurement.bicepsRight.toString()
        : '';
    _bicepsLeftController.text = measurement.bicepsLeft > 0
        ? measurement.bicepsLeft.toString()
        : '';
    _hipsController.text = measurement.hipsCircumference != null
        ? measurement.hipsCircumference.toString()
        : '';
    _thighRightController.text = measurement.thighRight != null
        ? measurement.thighRight.toString()
        : '';
    _thighLeftController.text = measurement.thighLeft != null
        ? measurement.thighLeft.toString()
        : '';

    // New Split Calves
    _calvesRightController.text = measurement.calvesRight != null
        ? measurement.calvesRight.toString()
        : '';
    _calvesLeftController.text = measurement.calvesLeft != null
        ? measurement.calvesLeft.toString()
        : '';
    _neckController.text = measurement.neck != null
        ? measurement.neck.toString()
        : '';
    _shouldersController.text = measurement.shoulders != null
        ? measurement.shoulders.toString()
        : '';
    _forearmRightController.text = measurement.forearmRight != null
        ? measurement.forearmRight.toString()
        : '';
    _forearmLeftController.text = measurement.forearmLeft != null
        ? measurement.forearmLeft.toString()
        : '';

    _notesController.text = measurement.notes;

    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFilledParts());
  }

  void _updateFilledParts() {
    setState(() {
      _filledParts = BodyParts(
        abdomen: _hipsController
            .text
            .isNotEmpty, // Swap: Abdomen Prop is Visual Hips
        upperBody: _chestController.text.isNotEmpty,
        lowerBody: _waistController
            .text
            .isNotEmpty, // Swap: LowerBody Prop is Visual Waist

        rightUpperArm: _bicepsLeftController.text.isNotEmpty, // Mirror
        leftUpperArm: _bicepsRightController.text.isNotEmpty, // Mirror

        rightUpperLeg: _thighLeftController.text.isNotEmpty, // Mirror
        leftUpperLeg: _thighRightController.text.isNotEmpty, // Mirror

        rightLowerLeg: _calvesLeftController.text.isNotEmpty, // Mirror
        leftLowerLeg: _calvesRightController.text.isNotEmpty, // Mirror

        neck: _neckController.text.isNotEmpty,
        head: _neckController.text.isNotEmpty, // Light up head too
        leftShoulder: _shouldersController.text.isNotEmpty,
        rightShoulder: _shouldersController.text.isNotEmpty,
        rightLowerArm: _forearmLeftController.text.isNotEmpty, // Mirror
        leftLowerArm: _forearmRightController.text.isNotEmpty, // Mirror
      );
    });
  }

  void _calculateBMI() {
    final weightText = _weightController.text.replaceAll(',', '.');
    final weight = double.tryParse(weightText);
    const height = 1.70; // Fixed height

    if (weight != null && weight > 0) {
      setState(() {
        _currentBMI = weight / (height * height);
      });
    } else {
      setState(() {
        _currentBMI = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _weightController.dispose();
    _waistController.dispose();
    _chestController.dispose();
    _bicepsRightController.dispose();
    _bicepsLeftController.dispose();
    _hipsController.dispose();
    _thighRightController.dispose();
    _thighLeftController.dispose();
    _calvesRightController.dispose();
    _calvesLeftController.dispose();
    _neckController.dispose();
    _shouldersController.dispose();
    _forearmRightController.dispose();
    _forearmLeftController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.black,
              surface: Colors.grey,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Handle Body Part Selection
  void _onBodyPartsSelected(BodyParts parts) {
    if (parts == _filledParts) return;

    // V5 FIXED MAPPING: Strict Visual Match

    if (parts.upperBody != _filledParts.upperBody) {
      _showMeasurementModal(
        "Peitoral",
        _chestController,
        "Medida na linha dos mamilos",
      );
    } else if (parts.abdomen != _filledParts.abdomen) {
      // Logic Swap: Abdomen Prop -> Visual Hips -> Open Hips Modal
      _showMeasurementModal(
        "Quadril",
        _hipsController,
        "Maior circunferência dos glúteos",
      );
    } else if (parts.lowerBody != _filledParts.lowerBody) {
      // Logic Swap: LowerBody Prop -> Visual Waist -> Open Waist Modal
      _showMeasurementModal(
        "Abdomen/Cintura",
        _waistController,
        "Medida na altura do umbigo",
      );
    } else if (parts.rightUpperArm != _filledParts.rightUpperArm) {
      _showMeasurementModal(
        "Bíceps (Esq.)",
        _bicepsLeftController,
        "Braço esquerdo relaxado",
      );
    } else if (parts.leftUpperArm != _filledParts.leftUpperArm) {
      _showMeasurementModal(
        "Bíceps (Dir.)",
        _bicepsRightController,
        "Braço direito relaxado",
      );
    } else if (parts.rightUpperLeg != _filledParts.rightUpperLeg) {
      _showMeasurementModal(
        "Coxa (Esq.)",
        _thighLeftController,
        "Coxa esquerda (parte mais larga)",
      );
    } else if (parts.leftUpperLeg != _filledParts.leftUpperLeg) {
      _showMeasurementModal(
        "Coxa (Dir.)",
        _thighRightController,
        "Coxa direita (parte mais larga)",
      );
    } else if (parts.rightLowerLeg != _filledParts.rightLowerLeg) {
      _showMeasurementModal(
        "Panturrilha (Esq.)",
        _calvesLeftController,
        "Panturrilha esquerda (maior circunferência)",
      );
    } else if (parts.leftLowerLeg != _filledParts.leftLowerLeg) {
      _showMeasurementModal(
        "Panturrilha (Dir.)",
        _calvesRightController,
        "Panturrilha direita (maior circunferência)",
      );
    } else if (parts.head != _filledParts.head ||
        parts.neck != _filledParts.neck) {
      _showMeasurementModal(
        "Pescoço",
        _neckController,
        "Circunferência do pescoço (meio)",
      );
    } else if (parts.leftShoulder != _filledParts.leftShoulder ||
        parts.rightShoulder != _filledParts.rightShoulder) {
      _showMeasurementModal(
        "Ombros",
        _shouldersController,
        "Circunferência total dos ombros",
      );
    } else if (parts.rightLowerArm != _filledParts.rightLowerArm) {
      // Mirror: Package Right -> User Left Forearm
      _showMeasurementModal(
        "Antebraço (Esq.)",
        _forearmLeftController,
        "Antebraço esquerdo (parte mais larga)",
      );
    } else if (parts.leftLowerArm != _filledParts.leftLowerArm) {
      // Mirror: Package Left -> User Right Forearm
      _showMeasurementModal(
        "Antebraço (Dir.)",
        _forearmRightController,
        "Antebraço direito (parte mais larga)",
      );
    }
  }

  void _showMeasurementModal(
    String label,
    TextEditingController controller,
    String helpText,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade900,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: helpText,
                    triggerMode: TooltipTriggerMode.tap,
                    child: Icon(
                      Icons.info_outline,
                      color: AppColors.primary.withOpacity(0.7),
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                decoration: const InputDecoration(
                  suffixText: "cm",
                  border: InputBorder.none,
                  hintText: "0.0",
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Confirmar"),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _areAllFieldsFilled() {
    return _weightController.text.isNotEmpty &&
        _waistController.text.isNotEmpty &&
        _chestController.text.isNotEmpty &&
        _bicepsRightController.text.isNotEmpty &&
        _bicepsLeftController.text.isNotEmpty &&
        _hipsController.text.isNotEmpty &&
        _thighRightController.text.isNotEmpty &&
        _thighLeftController.text.isNotEmpty &&
        _calvesRightController.text.isNotEmpty &&
        _calvesLeftController.text.isNotEmpty &&
        _neckController.text.isNotEmpty &&
        _shouldersController.text.isNotEmpty &&
        _forearmRightController.text.isNotEmpty &&
        _forearmLeftController.text.isNotEmpty;
  }

  void _saveMeasurement() {
    if (!_areAllFieldsFilled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos os campos (Peso e Medidas) são obrigatórios!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final measurement = BodyMeasurement(
        id: widget.measurementToEdit?.id ?? const Uuid().v4(),
        date: _selectedDate,
        weight:
            double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0,
        bmi: _currentBMI > 0 ? _currentBMI : null,
        waistCircumference:
            double.tryParse(_waistController.text.replaceAll(',', '.')) ?? 0,
        chestCircumference:
            double.tryParse(_chestController.text.replaceAll(',', '.')) ?? 0,
        bicepsRight:
            double.tryParse(_bicepsRightController.text.replaceAll(',', '.')) ??
            0,
        bicepsLeft:
            double.tryParse(_bicepsLeftController.text.replaceAll(',', '.')) ??
            0,
        hipsCircumference: double.tryParse(
          _hipsController.text.replaceAll(',', '.'),
        ),
        thighRight: double.tryParse(
          _thighRightController.text.replaceAll(',', '.'),
        ),
        thighLeft: double.tryParse(
          _thighLeftController.text.replaceAll(',', '.'),
        ),
        // Create Entity with new optional fields
        calvesRight: double.tryParse(
          _calvesRightController.text.replaceAll(',', '.'),
        ),
        calvesLeft: double.tryParse(
          _calvesLeftController.text.replaceAll(',', '.'),
        ),
        neck: double.tryParse(_neckController.text.replaceAll(',', '.')),
        shoulders: double.tryParse(
          _shouldersController.text.replaceAll(',', '.'),
        ),
        forearmRight: double.tryParse(
          _forearmRightController.text.replaceAll(',', '.'),
        ),
        forearmLeft: double.tryParse(
          _forearmLeftController.text.replaceAll(',', '.'),
        ),
        notes: _notesController.text,
      );

      ref.read(bodyTrackerProvider.notifier).addMeasurement(measurement);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.measurementToEdit != null ? 'Editar Medidas' : 'Nova Medição',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppColors.primary),
            onPressed: _saveMeasurement,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: TextFormField(
                            controller: _dateController,
                            decoration: const InputDecoration(
                              labelText: 'Data',
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Peso (kg)',
                          prefixIcon: Icon(
                            Icons.fitness_center,
                            color: AppColors.primary,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? '?' : null,
                      ),
                    ),
                  ],
                ),
              ),

              if (_currentBMI > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: BMIGauge(bmiValue: _currentBMI),
                ),

              const SizedBox(height: 20),

              // Body Selector Area
              SizedBox(
                height: 500,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: BodyPartSelector(
                        bodyParts: _filledParts,
                        onSelectionUpdated: _onBodyPartsSelected,
                        side: _selectedSide,
                        mirrored: false,
                        selectedColor: AppColors.primary,
                        unselectedColor: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    Positioned(
                      right: 20,
                      bottom: 20,
                      child: FloatingActionButton.small(
                        backgroundColor: Colors.grey.shade800,
                        child: Icon(
                          _selectedSide == BodySide.front
                              ? Icons.flip_camera_android
                              : Icons.accessibility_new,
                          color: AppColors.primary,
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedSide = _selectedSide == BodySide.front
                                ? BodySide.back
                                : BodySide.front;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ExpansionTile(
                title: const Text(
                  "Medidas Registradas",
                  style: TextStyle(color: AppColors.primary),
                ),
                initiallyExpanded: true,
                children: [
                  _buildSummaryLine(
                    "Peitoral",
                    _chestController,
                    "Medida na linha dos mamilos",
                  ),
                  _buildSummaryLine(
                    "Cintura",
                    _waistController,
                    "Medida na altura do umbigo",
                  ),
                  _buildSummaryLine(
                    "Quadril",
                    _hipsController,
                    "Maior circunferência dos glúteos",
                  ),
                  _buildSummaryLine(
                    "Bíceps (Dir.)",
                    _bicepsRightController,
                    "Braço direito relaxado",
                  ),
                  _buildSummaryLine(
                    "Bíceps (Esq.)",
                    _bicepsLeftController,
                    "Braço esquerdo relaxado",
                  ),
                  _buildSummaryLine(
                    "Coxa (Dir.)",
                    _thighRightController,
                    "Coxa direita (parte mais larga)",
                  ),
                  _buildSummaryLine(
                    "Coxa (Esq.)",
                    _thighLeftController,
                    "Coxa esquerda (parte mais larga)",
                  ),
                  _buildSummaryLine(
                    "Panturrilha (Dir.)",
                    _calvesRightController,
                    "Panturrilha direita (maior circunferência)",
                  ),
                  _buildSummaryLine(
                    "Panturrilha (Esq.)",
                    _calvesLeftController,
                    "Panturrilha esquerda (maior circunferência)",
                  ),
                  _buildSummaryLine(
                    "Pescoço",
                    _neckController,
                    "Circunferência do pescoço (meio)",
                  ),
                  _buildSummaryLine(
                    "Ombros",
                    _shouldersController,
                    "Circunferência total dos ombros",
                  ),
                  _buildSummaryLine(
                    "Antebraço (Dir.)",
                    _forearmRightController,
                    "Antebraço direito (parte mais larga)",
                  ),
                  _buildSummaryLine(
                    "Antebraço (Esq.)",
                    _forearmLeftController,
                    "Antebraço esquerdo (parte mais larga)",
                  ),
                ],
              ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas / Observações',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryLine(
    String label,
    TextEditingController controller,
    String helpText,
  ) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return ListTile(
          dense: true,
          leading: Icon(
            controller.text.isNotEmpty
                ? Icons.check_circle
                : Icons.circle_outlined,
            color: controller.text.isNotEmpty ? AppColors.primary : Colors.grey,
            size: 20,
          ),
          title: Row(
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              const SizedBox(width: 5),
              Tooltip(
                message: helpText,
                triggerMode: TooltipTriggerMode.tap,
                child: const Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          trailing: Text(
            controller.text.isNotEmpty ? "${controller.text} cm" : "-",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: controller.text.isNotEmpty
                  ? Colors.white
                  : Colors.grey.shade700,
            ),
          ),
          onTap: () => _showMeasurementModal(label, controller, helpText),
        );
      },
    );
  }
}
