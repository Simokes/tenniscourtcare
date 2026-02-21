enum Role {
  admin(label: 'Administrateur', description: 'Accès complet au système'),
  agent(label: 'Agent de maintenance', description: 'Gestion des interventions et du planning'),
  secretary(label: 'Secrétaire', description: 'Gestion du planning et des réservations');

  final String label;
  final String description;

  const Role({required this.label, required this.description});
}
