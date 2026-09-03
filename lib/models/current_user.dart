import '../core/services/token_storage.dart';

/// The signed-in customer, read from the `user` object persisted by
/// [TokenStorage] after a successful login/onboarding.
class CurrentUser {
  const CurrentUser({required this.name, required this.email, required this.phone});

  final String name;
  final String email;
  final String phone;

  /// Up to two initials derived from [name], for avatar badges.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  /// Reads the current user from local storage, or null if nobody is
  /// logged in / the saved data is missing a name.
  static Future<CurrentUser?> load() async {
    final authData = await TokenStorage.readAuthData();
    final user = authData?['user'] as Map<String, dynamic>?;
    final name = user?['name'] as String?;
    if (name == null || name.isEmpty) return null;
    return CurrentUser(
      name: name,
      email: user?['email'] as String? ?? '',
      phone: user?['phone'] as String? ?? '',
    );
  }
}
