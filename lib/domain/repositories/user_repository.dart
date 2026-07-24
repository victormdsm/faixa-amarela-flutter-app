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
}
