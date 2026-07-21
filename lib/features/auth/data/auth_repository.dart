import 'package:fastswipe/features/auth/data/models/user.dart';

abstract class AuthRepository {
  Future<User> login({
    required String email,
    required String password,
    required UserRole role,
  });

  Future<void> logout();
}

/// Stands in for the real backend until the auth endpoint contract is
/// available. Accepts any credentials and returns a fake [User] for the
/// requested role, so the rest of the app (routing, role-based dashboards)
/// can be built and demoed end-to-end today.
class MockAuthRepository implements AuthRepository {
  @override
  Future<User> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return User(
      id: 'mock-user-id',
      name: email.split('@').first,
      email: email,
      role: role,
    );
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
