import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/core/theme/app_theme.dart';
import 'package:tenniscourtcare/features/auth/presentation/pages/login_page.dart';

void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(body: LoginPage()),
      ),
    ),
  );
}
