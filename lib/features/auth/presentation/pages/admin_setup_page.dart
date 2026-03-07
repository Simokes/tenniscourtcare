import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/data/repositories/firebase_auth_repository.dart';
import 'package:tenniscourtcare/features/auth/providers/setup_providers.dart';
import 'package:tenniscourtcare/features/auth/providers/auth_providers.dart';

class AdminSetupPage extends ConsumerStatefulWidget {
  const AdminSetupPage({super.key});

  @override
  ConsumerState<AdminSetupPage> createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends ConsumerState<AdminSetupPage> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _nameController;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _createAdmin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Note: We need to cast or ensure the provider returns FirebaseAuthRepository
      // Assuming authRepositoryProvider returns AuthRepository interface which FirebaseAuthRepository implements
      // And assuming createAdminUser is in the interface or we cast.
      // The instruction said: "ref.read(authRepositoryProvider).createAdminUser(...)".
      // I will assume authRepositoryProvider exposes this method or the concrete class.
      // If authRepositoryProvider is defined as Provider<AuthRepository>, and AuthRepository interface
      // doesn't have createAdminUser, we might need a specific provider or cast.
      // For now, I'll try to use it as requested. If compile fails, I'll fix.
      // Actually, checking previous instructions, item 4 says "Verify createAdminUser in FirebaseAuthRepository".
      // If it's not in the interface, we can't call it on the interface provider easily without casting.
      // I'll check imports.

      final repo = ref.read(authRepositoryProvider);

      // If repo is FirebaseAuthRepository, we can cast.
      if (repo is FirebaseAuthRepository) {
        await repo.createAdminUser(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          name: _nameController.text.trim(),
        );
      } else {
        throw Exception('Repository is not FirebaseAuthRepository');
      }

      // ✅ Trigger setup status refresh
      ref.invalidate(setupStatusProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Admin créé avec succès!')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration Admin')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton(
              onPressed: _isLoading ? null : _createAdmin,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Créer Admin'),
            ),
          ],
        ),
      ),
    );
  }
}
