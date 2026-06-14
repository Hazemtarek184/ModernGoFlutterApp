import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modern_go/core/constants/app_colors.dart';
import 'package:modern_go/features/health_profile/presentation/bloc/health_profile_bloc.dart';
import 'package:modern_go/features/health_profile/presentation/pages/edit_health_profile_page.dart';

class HealthProfilePage extends StatefulWidget {
  const HealthProfilePage({super.key});

  @override
  State<HealthProfilePage> createState() => _HealthProfilePageState();
}

class _HealthProfilePageState extends State<HealthProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<HealthProfileBloc>().add(LoadHealthProfile());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Health Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: BlocConsumer<HealthProfileBloc, HealthProfileState>(
        listener: (context, state) {
          if (state is HealthProfileNotFound) {
            // Automatically redirect to create profile if not found
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      const EditHealthProfilePage(isInitialCreation: true)),
            );
          } else if (state is HealthProfileSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            if (state.message.contains('deleted')) {
              // Redirect back to edit or settings? Let's just pop if deleted
              Navigator.pop(context);
            }
          } else if (state is HealthProfileError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is HealthProfileLoading || state is HealthProfileNotFound) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is HealthProfileLoaded) {
            return _buildProfileContent(context, state);
          } else if (state is HealthProfileSuccess && state.profile != null) {
            return _buildProfileContent(context, HealthProfileLoaded(state.profile!));
          } else if (state is HealthProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<HealthProfileBloc>().add(LoadHealthProfile()),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, HealthProfileLoaded state) {
    final profile = state.profile;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('General Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.edit, color: AppColors.primary),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EditHealthProfilePage(profile: profile)),
                  );
                },
              )
            ],
          ),
          const Divider(),
          _buildInfoRow('Age', '${profile.age ?? 'Not set'}'),
          _buildInfoRow('Sex', profile.sex ?? 'Not set'),
          _buildInfoRow('Weight', profile.weightKg != null ? '${profile.weightKg} kg' : 'Not set'),
          _buildInfoRow('Height', profile.heightCm != null ? '${profile.heightCm} cm' : 'Not set'),
          _buildInfoRow('Pregnant', profile.pregnant == true ? 'Yes' : 'No'),
          
          const SizedBox(height: 24),
          const Text('Allergies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          if (profile.allergies == null || profile.allergies!.isEmpty)
            const Text('None reported', style: TextStyle(color: Colors.grey))
          else
            ...profile.allergies!.map((a) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(a.allergen),
              subtitle: Text('Severity: ${a.severity ?? 'Unknown'}'),
            )),

          const SizedBox(height: 24),
          const Text('Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          if (profile.conditions == null || profile.conditions!.isEmpty)
            const Text('None reported', style: TextStyle(color: Colors.grey))
          else
            ...profile.conditions!.map((c) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(c.name),
              subtitle: Text('ICD-10: ${c.icd10 ?? 'N/A'} | Severity: ${c.severity ?? 'Unknown'}'),
            )),

          const SizedBox(height: 24),
          const Text('Medications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          if (profile.medications == null || profile.medications!.isEmpty)
            const Text('None reported', style: TextStyle(color: Colors.grey))
          else
            ...profile.medications!.map((m) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.name),
              subtitle: Text('${m.doseMg ?? '?'} mg | ${m.frequencyPerDay ?? '?'} times/day'),
            )),

          const SizedBox(height: 24),
          const Text('Dietary Restrictions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          if (profile.dietaryRestrictions == null || profile.dietaryRestrictions!.isEmpty)
            const Text('None reported', style: TextStyle(color: Colors.grey))
          else
            Wrap(
              spacing: 8,
              children: profile.dietaryRestrictions!.map((d) => Chip(label: Text(d))).toList(),
            ),

          const SizedBox(height: 24),
          const Text('Risk Factors', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          if (profile.riskFactors == null)
            const Text('None reported', style: TextStyle(color: Colors.grey))
          else ...[
            _buildInfoRow('Hypertension', profile.riskFactors!.hypertension == true ? 'Yes' : 'No'),
            _buildInfoRow('Kidney Disease', profile.riskFactors!.kidneyDisease == true ? 'Yes' : 'No'),
            _buildInfoRow('Liver Disease', profile.riskFactors!.liverDisease == true ? 'Yes' : 'No'),
          ],

          const SizedBox(height: 48),
          Center(
            child: TextButton.icon(
              onPressed: () {
                _showDeleteDialog(context);
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Delete Health Profile', style: TextStyle(color: Colors.red)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Profile?'),
        content: const Text('Are you sure you want to delete your health profile? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<HealthProfileBloc>().add(DeleteProfile());
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
