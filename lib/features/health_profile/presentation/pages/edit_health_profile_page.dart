import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/health_profile/domain/entities/health_profile.dart';
import 'package:modern_go/features/health_profile/presentation/bloc/health_profile_bloc.dart';
import 'package:modern_go/features/health_profile/presentation/pages/health_profile_page.dart';

class EditHealthProfilePage extends StatefulWidget {
  final HealthProfile? profile;
  final bool isInitialCreation;

  const EditHealthProfilePage({super.key, this.profile, this.isInitialCreation = false});

  @override
  State<EditHealthProfilePage> createState() => _EditHealthProfilePageState();
}

class _EditHealthProfilePageState extends State<EditHealthProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _ageController;
  String? _selectedSex;
  late TextEditingController _weightController;
  late TextEditingController _heightController;
  bool _isPregnant = false;
  
  bool _hypertension = false;
  bool _kidneyDisease = false;
  bool _liverDisease = false;

  List<Allergy> _allergies = [];
  List<Condition> _conditions = [];
  List<Medication> _medications = [];
  List<String> _dietaryRestrictions = [];

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _ageController = TextEditingController(text: p?.age?.toString() ?? '');
    _selectedSex = p?.sex;
    _weightController = TextEditingController(text: p?.weightKg?.toString() ?? '');
    _heightController = TextEditingController(text: p?.heightCm?.toString() ?? '');
    _isPregnant = p?.pregnant ?? false;
    
    _hypertension = p?.riskFactors?.hypertension ?? false;
    _kidneyDisease = p?.riskFactors?.kidneyDisease ?? false;
    _liverDisease = p?.riskFactors?.liverDisease ?? false;

    _allergies = List.from(p?.allergies ?? []);
    _conditions = List.from(p?.conditions ?? []);
    _medications = List.from(p?.medications ?? []);
    _dietaryRestrictions = List.from(p?.dietaryRestrictions ?? []);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final newProfile = HealthProfile(
        age: int.tryParse(_ageController.text),
        sex: _selectedSex,
        weightKg: double.tryParse(_weightController.text),
        heightCm: double.tryParse(_heightController.text),
        pregnant: _isPregnant,
        riskFactors: RiskFactors(
          hypertension: _hypertension,
          kidneyDisease: _kidneyDisease,
          liverDisease: _liverDisease,
        ),
        allergies: _allergies.isNotEmpty ? _allergies : null,
        conditions: _conditions.isNotEmpty ? _conditions : null,
        medications: _medications.isNotEmpty ? _medications : null,
        dietaryRestrictions: _dietaryRestrictions.isNotEmpty ? _dietaryRestrictions : null,
      );

      if (widget.profile == null) {
        context.read<HealthProfileBloc>().add(CreateProfile(newProfile));
      } else {
        context.read<HealthProfileBloc>().add(UpdateProfile(newProfile));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile == null ? 'Create Profile' : 'Edit Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.grey[50],
      body: BlocConsumer<HealthProfileBloc, HealthProfileState>(
        listener: (context, state) {
          if (state is HealthProfileSuccess) {
            if (widget.isInitialCreation) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HealthProfilePage()),
              );
            } else {
              Navigator.pop(context);
              context.read<HealthProfileBloc>().add(LoadHealthProfile());
            }
          } else if (state is HealthProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is HealthProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionCard(
                    title: 'General Information',
                    children: [
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(labelText: 'Age (0-120)', border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val != null && val.isNotEmpty) {
                            final parsed = int.tryParse(val);
                            if (parsed == null || parsed < 0 || parsed > 120) return 'Enter a valid age (0-120)';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedSex,
                        decoration: const InputDecoration(labelText: 'Sex', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(value: 'female', child: Text('Female')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedSex = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              decoration: const InputDecoration(labelText: 'Weight (kg)', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) {
                                if (val != null && val.isNotEmpty) {
                                  final parsed = double.tryParse(val);
                                  if (parsed == null || parsed <= 0 || parsed > 500) return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              decoration: const InputDecoration(labelText: 'Height (cm)', border: OutlineInputBorder()),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) {
                                if (val != null && val.isNotEmpty) {
                                  final parsed = double.tryParse(val);
                                  if (parsed == null || parsed <= 0 || parsed > 250) return 'Invalid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Pregnant'),
                        value: _isPregnant,
                        onChanged: (val) {
                          setState(() {
                            _isPregnant = val;
                          });
                        },
                      ),
                    ],
                  ),
                  
                  _buildSectionCard(
                    title: 'Risk Factors',
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hypertension'),
                        value: _hypertension,
                        onChanged: (val) => setState(() => _hypertension = val ?? false),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Kidney Disease'),
                        value: _kidneyDisease,
                        onChanged: (val) => setState(() => _kidneyDisease = val ?? false),
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Liver Disease'),
                        value: _liverDisease,
                        onChanged: (val) => setState(() => _liverDisease = val ?? false),
                      ),
                    ],
                  ),

                  _buildAllergiesSection(),
                  _buildConditionsSection(),
                  _buildMedicationsSection(),
                  _buildDietaryRestrictionsSection(),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Profile', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // --- Allergies ---
  Widget _buildAllergiesSection() {
    return _buildSectionCard(
      title: 'Allergies',
      children: [
        ..._allergies.map((a) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(a.allergen),
          subtitle: Text('Severity: ${a.severity ?? 'None'}'),
          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _allergies.remove(a))),
        )),
        TextButton.icon(
          onPressed: _addAllergyDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Allergy'),
        ),
      ],
    );
  }

  void _addAllergyDialog() {
    final nameCtrl = TextEditingController();
    String? severity;
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Add Allergy'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Allergen Name')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Severity'),
              items: const [
                DropdownMenuItem(value: 'mild', child: Text('Mild')),
                DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                DropdownMenuItem(value: 'severe', child: Text('Severe')),
              ],
              onChanged: (val) => severity = val,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.length >= 2) {
                setState(() => _allergies.add(Allergy(allergen: nameCtrl.text, severity: severity)));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          )
        ],
      );
    });
  }

  // --- Conditions ---
  Widget _buildConditionsSection() {
    return _buildSectionCard(
      title: 'Conditions',
      children: [
        ..._conditions.map((c) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(c.name),
          subtitle: Text('Severity: ${c.severity ?? 'None'} | ICD-10: ${c.icd10 ?? 'N/A'}'),
          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _conditions.remove(c))),
        )),
        TextButton.icon(
          onPressed: _addConditionDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Condition'),
        ),
      ],
    );
  }

  void _addConditionDialog() {
    final nameCtrl = TextEditingController();
    final icd10Ctrl = TextEditingController();
    String? severity;
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Add Condition'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Condition Name')),
            const SizedBox(height: 16),
            TextField(controller: icd10Ctrl, decoration: const InputDecoration(labelText: 'ICD-10 (Optional)')),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Severity'),
              items: const [
                DropdownMenuItem(value: 'mild', child: Text('Mild')),
                DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                DropdownMenuItem(value: 'severe', child: Text('Severe')),
              ],
              onChanged: (val) => severity = val,
            )
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.length >= 2) {
                setState(() => _conditions.add(Condition(
                  name: nameCtrl.text,
                  icd10: icd10Ctrl.text.isNotEmpty ? icd10Ctrl.text : null,
                  severity: severity,
                )));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          )
        ],
      );
    });
  }

  // --- Medications ---
  Widget _buildMedicationsSection() {
    return _buildSectionCard(
      title: 'Medications',
      children: [
        ..._medications.map((m) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(m.name),
          subtitle: Text('${m.doseMg ?? '?'} mg | ${m.frequencyPerDay ?? '?'} times/day'),
          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _medications.remove(m))),
        )),
        TextButton.icon(
          onPressed: _addMedicationDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Medication'),
        ),
      ],
    );
  }

  void _addMedicationDialog() {
    final nameCtrl = TextEditingController();
    final doseCtrl = TextEditingController();
    final freqCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Add Medication'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Medication Name')),
            const SizedBox(height: 16),
            TextField(controller: doseCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Dose (mg)')),
            const SizedBox(height: 16),
            TextField(controller: freqCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Frequency (per day)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.length >= 2) {
                setState(() => _medications.add(Medication(
                  name: nameCtrl.text,
                  doseMg: double.tryParse(doseCtrl.text),
                  frequencyPerDay: int.tryParse(freqCtrl.text),
                )));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          )
        ],
      );
    });
  }

  // --- Dietary Restrictions ---
  Widget _buildDietaryRestrictionsSection() {
    return _buildSectionCard(
      title: 'Dietary Restrictions',
      children: [
        Wrap(
          spacing: 8,
          children: _dietaryRestrictions.map((d) => Chip(
            label: Text(d),
            onDeleted: () => setState(() => _dietaryRestrictions.remove(d)),
          )).toList(),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _addDietaryDialog,
          icon: const Icon(Icons.add),
          label: const Text('Add Dietary Restriction'),
        ),
      ],
    );
  }

  void _addDietaryDialog() {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Add Restriction'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Restriction Name (e.g. Vegan)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (ctrl.text.length >= 2) {
                setState(() => _dietaryRestrictions.add(ctrl.text));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          )
        ],
      );
    });
  }
}
