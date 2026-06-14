import 'package:equatable/equatable.dart';

class HealthProfile extends Equatable {
  final int? age;
  final String? sex;
  final double? weightKg;
  final double? heightCm;
  final bool? pregnant;
  final List<Allergy>? allergies;
  final List<Condition>? conditions;
  final List<Medication>? medications;
  final List<String>? dietaryRestrictions;
  final RiskFactors? riskFactors;

  const HealthProfile({
    this.age,
    this.sex,
    this.weightKg,
    this.heightCm,
    this.pregnant,
    this.allergies,
    this.conditions,
    this.medications,
    this.dietaryRestrictions,
    this.riskFactors,
  });

  @override
  List<Object?> get props => [
        age,
        sex,
        weightKg,
        heightCm,
        pregnant,
        allergies,
        conditions,
        medications,
        dietaryRestrictions,
        riskFactors,
      ];
}

class Allergy extends Equatable {
  final String allergen;
  final String? severity;

  const Allergy({
    required this.allergen,
    this.severity,
  });

  @override
  List<Object?> get props => [allergen, severity];
}

class Condition extends Equatable {
  final String name;
  final String? icd10;
  final String? severity;

  const Condition({
    required this.name,
    this.icd10,
    this.severity,
  });

  @override
  List<Object?> get props => [name, icd10, severity];
}

class Medication extends Equatable {
  final String name;
  final double? doseMg;
  final int? frequencyPerDay;

  const Medication({
    required this.name,
    this.doseMg,
    this.frequencyPerDay,
  });

  @override
  List<Object?> get props => [name, doseMg, frequencyPerDay];
}

class RiskFactors extends Equatable {
  final bool? hypertension;
  final bool? kidneyDisease;
  final bool? liverDisease;

  const RiskFactors({
    this.hypertension,
    this.kidneyDisease,
    this.liverDisease,
  });

  @override
  List<Object?> get props => [hypertension, kidneyDisease, liverDisease];
}
