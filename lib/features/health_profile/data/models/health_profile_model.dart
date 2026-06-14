import 'package:modern_go/features/health_profile/domain/entities/health_profile.dart';

class HealthProfileModel extends HealthProfile {
  const HealthProfileModel({
    super.age,
    super.sex,
    super.weightKg,
    super.heightCm,
    super.pregnant,
    super.allergies,
    super.conditions,
    super.medications,
    super.dietaryRestrictions,
    super.riskFactors,
  });

  factory HealthProfileModel.fromJson(Map<String, dynamic> json) {
    return HealthProfileModel(
      age: json['age'] as int?,
      sex: json['sex'] as String?,
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      pregnant: json['pregnant'] as bool?,
      allergies: json['allergies'] != null
          ? (json['allergies'] as List)
              .map((e) => AllergyModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : null,
      conditions: json['conditions'] != null
          ? (json['conditions'] as List)
              .map((e) => ConditionModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : null,
      medications: json['medications'] != null
          ? (json['medications'] as List)
              .map((e) => MedicationModel.fromJson(Map<String, dynamic>.from(e as Map)))
              .toList()
          : null,
      dietaryRestrictions: json['dietaryRestrictions'] != null
          ? List<String>.from(json['dietaryRestrictions'] as List)
          : null,
      riskFactors: json['riskFactors'] != null
          ? RiskFactorsModel.fromJson(Map<String, dynamic>.from(json['riskFactors'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (age != null) data['age'] = age;
    if (sex != null) data['sex'] = sex;
    if (weightKg != null) data['weightKg'] = weightKg;
    if (heightCm != null) data['heightCm'] = heightCm;
    if (pregnant != null) data['pregnant'] = pregnant;
    if (allergies != null) {
      data['allergies'] = allergies!.map((v) => (v as AllergyModel).toJson()).toList();
    }
    if (conditions != null) {
      data['conditions'] = conditions!.map((v) => (v as ConditionModel).toJson()).toList();
    }
    if (medications != null) {
      data['medications'] = medications!.map((v) => (v as MedicationModel).toJson()).toList();
    }
    if (dietaryRestrictions != null) {
      data['dietaryRestrictions'] = dietaryRestrictions;
    }
    if (riskFactors != null) {
      data['riskFactors'] = (riskFactors as RiskFactorsModel).toJson();
    }
    return data;
  }
}

class AllergyModel extends Allergy {
  const AllergyModel({
    required super.allergen,
    super.severity,
  });

  factory AllergyModel.fromJson(Map<String, dynamic> json) {
    return AllergyModel(
      allergen: json['allergen'] as String,
      severity: json['severity'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['allergen'] = allergen;
    if (severity != null) data['severity'] = severity;
    return data;
  }
}

class ConditionModel extends Condition {
  const ConditionModel({
    required super.name,
    super.icd10,
    super.severity,
  });

  factory ConditionModel.fromJson(Map<String, dynamic> json) {
    return ConditionModel(
      name: json['name'] as String,
      icd10: json['icd10'] as String?,
      severity: json['severity'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (icd10 != null) data['icd10'] = icd10;
    if (severity != null) data['severity'] = severity;
    return data;
  }
}

class MedicationModel extends Medication {
  const MedicationModel({
    required super.name,
    super.doseMg,
    super.frequencyPerDay,
  });

  factory MedicationModel.fromJson(Map<String, dynamic> json) {
    return MedicationModel(
      name: json['name'] as String,
      doseMg: (json['doseMg'] as num?)?.toDouble(),
      frequencyPerDay: json['frequencyPerDay'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    if (doseMg != null) data['doseMg'] = doseMg;
    if (frequencyPerDay != null) data['frequencyPerDay'] = frequencyPerDay;
    return data;
  }
}

class RiskFactorsModel extends RiskFactors {
  const RiskFactorsModel({
    super.hypertension,
    super.kidneyDisease,
    super.liverDisease,
  });

  factory RiskFactorsModel.fromJson(Map<String, dynamic> json) {
    return RiskFactorsModel(
      hypertension: json['hypertension'] as bool?,
      kidneyDisease: json['kidneyDisease'] as bool?,
      liverDisease: json['liverDisease'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (hypertension != null) data['hypertension'] = hypertension;
    if (kidneyDisease != null) data['kidneyDisease'] = kidneyDisease;
    if (liverDisease != null) data['liverDisease'] = liverDisease;
    return data;
  }
}
