import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/profile_repository.dart';
import 'auth_provider.dart';

final profileProvider = FutureProvider<UserModel>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  final user = await repo.getProfile();
  
  // Sync the updated user profile into AuthState and SecureStorage
  ref.read(authProvider.notifier).updateUser(user);
  
  return user;
});
