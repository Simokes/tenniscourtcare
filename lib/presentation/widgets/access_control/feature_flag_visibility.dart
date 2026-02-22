import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_providers.dart';
import '../../../domain/enums/feature_flag.dart';
import '../../../domain/logic/permission_resolver.dart';

class FeatureFlagVisibility extends ConsumerWidget {
  final FeatureFlag featureFlag;
  final Widget child;
  final Widget? fallback;

  const FeatureFlagVisibility({
    super.key,
    required this.featureFlag,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user != null && PermissionResolver.isFeatureEnabled(user.role, featureFlag)) {
      return child;
    }
    return fallback ?? const SizedBox.shrink();
  }
}
