import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/club_info_provider.dart';
import '../../../../domain/entities/club_info.dart';
import '../../../widgets/premium/premium_card.dart';
import '../../../providers/auth_providers.dart';

class ClubInfoSection extends ConsumerWidget {
  const ClubInfoSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clubInfoAsync = ref.watch(clubInfoProvider);
    final user = ref.watch(currentUserProvider);

    return PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Informations du club',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  final currentInfo = clubInfoAsync.valueOrNull;
                  _showEditClubInfoDialog(context, ref, currentInfo, user?.email);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          clubInfoAsync.when(
            data: (info) {
              if (info == null) {
                return Column(
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text('Aucune info configurée')),
                    ),
                    ElevatedButton(
                      onPressed: () => _showEditClubInfoDialog(context, ref, null, user?.email),
                      child: const Text('Configurer'),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.business),
                    title: const Text('Nom du club'),
                    subtitle: Text(info.name),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Adresse postale'),
                    subtitle: Text(info.address ?? 'Non renseignée'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: const Text('Téléphone'),
                    subtitle: Text(info.phone ?? 'Non renseigné'),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email contact'),
                    subtitle: Text(info.email ?? 'Non renseigné'),
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Text('Erreur: $err', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditClubInfoDialog(BuildContext context, WidgetRef ref, ClubInfo? currentInfo, String? userEmail) {
    final formKey = GlobalKey<FormState>();
    String name = currentInfo?.name ?? '';
    String? address = currentInfo?.address;
    String? phone = currentInfo?.phone;
    String? email = currentInfo?.email;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Modifier les informations'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Nom du club *'),
                  validator: (value) {
                    if (value == null || value.trim().length < 2) {
                      return 'Minimum 2 caractères requis';
                    }
                    return null;
                  },
                  onSaved: (value) => name = value!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: address,
                  decoration: const InputDecoration(labelText: 'Adresse postale'),
                  onSaved: (value) => address = value?.trim().isEmpty ?? true ? null : value!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: phone,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  keyboardType: TextInputType.phone,
                  onSaved: (value) => phone = value?.trim().isEmpty ?? true ? null : value!.trim(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: email,
                  decoration: const InputDecoration(labelText: 'Email contact'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                      if (!emailRegex.hasMatch(value.trim())) {
                        return 'Format d\'email invalide';
                      }
                    }
                    return null;
                  },
                  onSaved: (value) => email = value?.trim().isEmpty ?? true ? null : value!.trim(),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();

                final newInfo = ClubInfo(
                  id: currentInfo?.id ?? 'main',
                  name: name,
                  address: address,
                  phone: phone,
                  email: email,
                  updatedAt: DateTime.now(),
                  updatedBy: userEmail,
                );

                ref.read(clubInfoNotifierProvider.notifier).saveClubInfo(newInfo);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
