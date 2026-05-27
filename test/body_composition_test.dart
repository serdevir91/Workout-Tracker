import 'package:flutter_test/flutter_test.dart';
import 'package:workout_tracker/utils/body_composition.dart';

void main() {
  group('BodyCompositionCalculator', () {
    test('returns male body composition when required inputs exist', () {
      final result = BodyCompositionCalculator.calculate(
        gender: BodyGender.male,
        heightCm: 180,
        weightKg: 80,
        waistCm: 86,
        neckCm: 40,
      );

      expect(result, isNotNull);
      expect(result!.bodyFatPercentage, greaterThanOrEqualTo(3));
      expect(result.bodyFatPercentage, lessThanOrEqualTo(60));
      expect(
        result.fatMassKg + result.leanMassKg,
        closeTo(80, 0.001),
      );
    });

    test('returns female body composition when hip measurement exists', () {
      final result = BodyCompositionCalculator.calculate(
        gender: BodyGender.female,
        heightCm: 168,
        weightKg: 64,
        waistCm: 74,
        neckCm: 33,
        hipCm: 96,
      );

      expect(result, isNotNull);
      expect(result!.bodyFatPercentage, greaterThan(3));
      expect(result.bodyFatPercentage, lessThan(60));
    });

    test('returns null when required measurements are missing', () {
      final result = BodyCompositionCalculator.calculate(
        gender: BodyGender.female,
        heightCm: 168,
        weightKg: 64,
        waistCm: 74,
        neckCm: 33,
      );

      expect(result, isNull);
    });

    test('clamps unrealistic body fat results into safe range', () {
      final result = BodyCompositionCalculator.calculate(
        gender: BodyGender.male,
        heightCm: 180,
        weightKg: 100,
        waistCm: 40,
        neckCm: 39.9,
      );

      expect(result, isNotNull);
      expect(result!.bodyFatPercentage, inInclusiveRange(3, 60));
    });
  });
}
