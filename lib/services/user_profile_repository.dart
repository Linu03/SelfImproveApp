import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class UserProfileRepository {
  static const String boxName = 'userProfileBox';
  static const String profileKey = 'userProfile';

  Future<Box<UserProfile>> openBox() async {
    return await Hive.openBox<UserProfile>(boxName);
  }

  Future<UserProfile> getProfile() async {
    final box = await openBox();
    if (box.containsKey(profileKey)) {
      return box.get(profileKey)!;
    }
    final profile = UserProfile(username: 'Player');
    await box.put(profileKey, profile);
    return profile;
  }

  Future<void> saveProfile(UserProfile profile) async {
    final box = await openBox();
    await box.put(profileKey, profile);
  }

  Future<void> setUsername(String username) async {
    final profile = await getProfile();
    profile.username = username;
    await saveProfile(profile);
  }

  Future<String> getUsername() async {
    final profile = await getProfile();
    return profile.username;
  }

  Future<void> setAvatarBytes(List<int> imageBytes) async {
    final profile = await getProfile();
    profile.avatarBytes = imageBytes;
    await saveProfile(profile);
  }

  Future<List<int>?> getAvatarBytes() async {
    final profile = await getProfile();
    return profile.avatarBytes;
  }

  Future<void> deleteAvatar() async {
    final profile = await getProfile();
    profile.avatarBytes = null;
    await saveProfile(profile);
  }
}
