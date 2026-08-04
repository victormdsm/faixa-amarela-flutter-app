import '../models/user_profile.dart';

abstract interface class UserRepository {
  Future<UserProfile> getMe();

  Future<UserProfile> updateMe({
    String? name,
    String? cellPhone,
  });

  Future<UserProfile> uploadAvatar(String filePath);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Solicita alteração de e-mail. O backend envia um link de confirmação
  /// para o novo e-mail; o app não precisa de tela de confirmação.
  Future<void> requestEmailChange({
    required String newEmail,
    required String currentPassword,
  });
}
