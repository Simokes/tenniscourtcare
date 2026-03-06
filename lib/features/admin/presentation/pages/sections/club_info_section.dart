import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/club_info_provider.dart';
import '../../../../../domain/entities/club_info.dart';
import '../../../../../shared/widgets/premium/premium_card.dart';
import '../../../../auth/providers/auth_providers.dart';

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
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text([info.street, info.postalCode, info.city]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(', ').isEmpty ? 'Non renseignée' : [info.street, info.postalCode, info.city]
                            .where((e) => e != null && e.isNotEmpty)
                            .join(', ')),
                        if (info.latitude != null && info.longitude != null)
                          Text(
                            '📍 Coordonnées GPS: ${info.latitude}, ${info.longitude}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                      ],
                    ),
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
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Horaires d\'ouverture'),
                    subtitle: Text(
                      '${info.openingHour ?? 8}h00 - ${info.closingHour ?? 21}h00',
                    ),
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
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EditClubInfoDialog(
        currentInfo: currentInfo,
        userEmail: userEmail,
      ),
    );
  }
}

class _EditClubInfoDialog extends ConsumerStatefulWidget {
  final ClubInfo? currentInfo;
  final String? userEmail;

  const _EditClubInfoDialog({
    this.currentInfo,
    this.userEmail,
  });

  @override
  ConsumerState<_EditClubInfoDialog> createState() => _EditClubInfoDialogState();
}

class _EditClubInfoDialogState extends ConsumerState<_EditClubInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  String? _street;
  String? _postalCode;
  String? _city;
  String? _phone;
  String? _email;
  int _openingHour = 8;
  int _closingHour = 21;

  @override
  void initState() {
    super.initState();
    _name = widget.currentInfo?.name ?? '';
    _street = widget.currentInfo?.street;
    _postalCode = widget.currentInfo?.postalCode;
    _city = widget.currentInfo?.city;
    _phone = widget.currentInfo?.phone;
    _email = widget.currentInfo?.email;
    _openingHour = widget.currentInfo?.openingHour ?? 8;
    _closingHour = widget.currentInfo?.closingHour ?? 21;
  }

  @override
  Widget build(BuildContext context) {
    final saveState = ref.watch(clubInfoNotifierProvider);
    final isLoading = saveState.isLoading;

    return AlertDialog(
      title: const Text('Modifier les informations'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: const InputDecoration(labelText: 'Nom du club *'),
                enabled: !isLoading,
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Minimum 2 caractères requis';
                  }
                  return null;
                },
                onSaved: (value) => _name = value!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _street,
                decoration: const InputDecoration(labelText: 'Rue et numéro'),
                enabled: !isLoading,
                onSaved: (value) => _street = value?.trim().isEmpty ?? true ? null : value!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _postalCode,
                decoration: const InputDecoration(labelText: 'Code postal'),
                keyboardType: TextInputType.number,
                enabled: !isLoading,
                onSaved: (value) => _postalCode = value?.trim().isEmpty ?? true ? null : value!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _city,
                decoration: const InputDecoration(labelText: 'Ville'),
                enabled: !isLoading,
                onSaved: (value) => _city = value?.trim().isEmpty ?? true ? null : value!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _phone,
                decoration: const InputDecoration(labelText: 'Téléphone'),
                keyboardType: TextInputType.phone,
                enabled: !isLoading,
                onSaved: (value) => _phone = value?.trim().isEmpty ?? true ? null : value!.trim(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _email,
                decoration: const InputDecoration(labelText: 'Email contact'),
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value.trim())) {
                      return 'Format d\'email invalide';
                    }
                  }
                  return null;
                },
                onSaved: (value) => _email = value?.trim().isEmpty ?? true ? null : value!.trim(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _openingHour,
                decoration: const InputDecoration(labelText: 'Heure d\'ouverture'),
                items: List.generate(5, (index) => index + 6).map((hour) {
                  return DropdownMenuItem(
                    value: hour,
                    child: Text('${hour}h00'),
                  );
                }).toList(),
                onChanged: isLoading ? null : (val) {
                  if (val != null) setState(() => _openingHour = val);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _closingHour,
                decoration: const InputDecoration(labelText: 'Heure de fermeture'),
                items: List.generate(6, (index) => index + 18).map((hour) {
                  return DropdownMenuItem(
                    value: hour,
                    child: Text('${hour}h00'),
                  );
                }).toList(),
                onChanged: isLoading ? null : (val) {
                  if (val != null) setState(() => _closingHour = val);
                },
              ),
              if (isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
                const SizedBox(height: 8),
                const Center(child: Text('Géocodage en cours...')),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: isLoading ? null : () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();

              final newInfo = ClubInfo(
                id: widget.currentInfo?.id ?? 'main',
                name: _name,
                street: _street,
                postalCode: _postalCode,
                city: _city,
                latitude: widget.currentInfo?.latitude,
                longitude: widget.currentInfo?.longitude,
                phone: _phone,
                email: _email,
                openingHour: _openingHour,
                closingHour: _closingHour,
                updatedAt: DateTime.now(),
                updatedBy: widget.userEmail,
              );

              try {
                await ref
                    .read(clubInfoNotifierProvider.notifier)
                    .saveClubInfo(newInfo);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }
          },
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
