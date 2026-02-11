import 'package:flutter/material.dart';

class BMIUtils {
  static String getBMIGrade(double? bmi) {
    if (bmi == null) return "";
    if (bmi < 18.5) return "Abaixo do Peso";
    if (bmi < 25.0) return "Peso Normal"; // Strict < 25.0
    if (bmi < 30.0) return "Sobrepeso"; // Strict < 30.0
    if (bmi < 35.0) return "Obesidade I"; // Strict < 35.0
    if (bmi < 40.0) return "Obesidade II"; // Strict < 40.0
    return "Obesidade III";
  }

  static Color getBMIColor(double? bmi) {
    if (bmi == null) return Colors.grey;
    if (bmi < 18.5) return const Color(0xFF00E5FF); // Blue (Underweight)
    if (bmi < 25.0) return const Color(0xFF00FF94); // Green (Normal)
    if (bmi < 30.0) return const Color(0xFFFFAA00); // Orange (Overweight)
    if (bmi < 35.0) return const Color(0xFFFF5500); // Dark Orange (Obesity I)
    if (bmi < 40.0) return const Color(0xFFFF0055); // Red/Pink (Obesity II)
    return const Color(0xFFCC0000); // Dark Red (Obesity III)
  }

  static double calculateBMI(double weightKg, double heightM) {
    if (heightM <= 0) return 0.0;
    return weightKg / (heightM * heightM);
  }
}
