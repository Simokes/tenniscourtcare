import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// StreamProvider that mimics the old isOnlineStatusProvider
final isOnlineStatusProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  // Initial value
  final result = await connectivity.checkConnectivity();
  bool isOnline(ConnectivityResult r) =>
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.ethernet;

  yield isOnline(result);

  // Stream changes
  yield* connectivity.onConnectivityChanged.map((result) {
    return isOnline(result);
  });
});
