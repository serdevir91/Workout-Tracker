import 'dart:math' as math;

enum BodyGender { male, female }
enum BmiCategory { underweight, normal, overweight, obese }

class BodyCompositionResult {
  const BodyCompositionResult({
    required this.bodyFatPercentage,
    required this.fatMassKg,
    required this.leanMassKg,
    required this.bmi,
    required this.bmiCategory,
  });

  final double bodyFatPercentage;
  final double fatMassKg;
  final double leanMassKg;
  final double bmi;
  final BmiCategory bmiCategory;
}

class BodyCompositionCalculator {
  static const double _minBodyFat = 3.0;
  static const double _maxBodyFat = 60.0;

  static BodyCompositionResult? calculate({
    required BodyGender gender,
    required double? heightCm,
    required double? weightKg,
    required double? waistCm,
    required double? neckCm,
    double? hipCm,
  }) {
    if (!_isPositive(heightCm) ||
        !_isPositive(weightKg) ||
        !_isPositive(waistCm) ||
        !_isPositive(neckCm)) {
      return null;
    }

    if (gender == BodyGender.female && !_isPositive(hipCm)) {
      return null;
    }

    final bodyFatPercentage = _clampBodyFat(
      gender == BodyGender.male
          ? _maleBodyFat(
              heightCm: heightCm!,
              waistCm: waistCm!,
              neckCm: neckCm!,
            )
          : _femaleBodyFat(
              heightCm: heightCm!,
              waistCm: waistCm!,
              neckCm: neckCm!,
              hipCm: hipCm!,
            ),
    );

    final fatMassKg = weightKg! * (bodyFatPercentage / 100.0);
    final leanMassKg = math.max(0.0, weightKg - fatMassKg).toDouble();
    final bmi = weightKg / math.pow(heightCm / 100.0, 2);

    return BodyCompositionResult(
      bodyFatPercentage: bodyFatPercentage,
      fatMassKg: fatMassKg,
      leanMassKg: leanMassKg,
      bmi: bmi,
      bmiCategory: _bmiCategory(bmi),
    );
  }

  static bool _isPositive(double? value) => value != null && value > 0;

  static double _maleBodyFat({
    required double heightCm,
    required double waistCm,
    required double neckCm,
  }) {
    final waistMinusNeck = waistCm - neckCm;
    if (waistMinusNeck <= 0) {
      return _minBodyFat;
    }

    final density =
        1.0324 - (0.19077 * _log10(waistMinusNeck)) + (0.15456 * _log10(heightCm));
    return (495.0 / density) - 450.0;
  }

  static double _femaleBodyFat({
    required double heightCm,
    required double waistCm,
    required double neckCm,
    required double hipCm,
  }) {
    final waistPlusHipMinusNeck = waistCm + hipCm - neckCm;
    if (waistPlusHipMinusNeck <= 0) {
      return _minBodyFat;
    }

    final density =
        1.29579 - (0.35004 * _log10(waistPlusHipMinusNeck)) + (0.22100 * _log10(heightCm));
    return (495.0 / density) - 450.0;
  }

  static double _log10(double value) => math.log(value) / math.ln10;

  static BmiCategory _bmiCategory(double bmi) {
    if (bmi < 18.5) {
      return BmiCategory.underweight;
    }
    if (bmi < 25.0) {
      return BmiCategory.normal;
    }
    if (bmi < 30.0) {
      return BmiCategory.overweight;
    }
    return BmiCategory.obese;
  }

  static double _clampBodyFat(double value) {
    if (value.isNaN || value.isInfinite) {
      return _minBodyFat;
    }
    return value.clamp(_minBodyFat, _maxBodyFat).toDouble();
  }
}
