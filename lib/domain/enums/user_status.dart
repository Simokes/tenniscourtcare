enum UserStatus {
  active(label: 'Actif'),
  inactive(label: 'En attente de validation'),
  rejected(label: 'Refusé');

  final String label;
  const UserStatus({required this.label});
}
